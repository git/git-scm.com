#!/usr/bin/env ruby

require "asciidoctor"
require "octokit"
require "time"
require "digest/sha1"
require "set"
require 'fileutils'
require 'yaml'
require 'diffy'
require_relative "version"

SITE_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), '../')
DATA_FILE = "#{SITE_ROOT}data/docs.yml"

def read_data
  if File.exists?(DATA_FILE)
    # `permitted_classes` required to allow running with Ruby v3.1
    data = YAML.load_file(DATA_FILE, permitted_classes: [Time])
  else
    FileUtils.mkdir_p(File.dirname(DATA_FILE))
    data = {}
  end

  data["versions"] = {} unless data["versions"]
  data["pages"] = {} if !data["pages"]

  data
end

def make_asciidoc(content)
  Asciidoctor::Document.new(content,
                            attributes: {
                              "sectanchors" => "",
                              "litdd" => "&\#x2d;&\#x2d;",
                              "compat-mode" => "",
                            },
                            doctype: "book")
end

def expand_l10n(path, content, get_f_content, categories)
  content.gsub!(/include::(\S+)\.txt/) do |line|
    line.gsub!("include::", "")
    if categories[line]
      new_content = categories[line]
    else
      new_content, new_path = get_f_content.call(path, line)
    end
    if new_content
      expand_l10n(new_path, new_content, get_f_content, categories)
    else
      "\n\n[WARNING]\n====\nMissing `#{new_path}`\n\nSee original version for this content.\n====\n\n"
    end
  end
  content
end

def index_l10n_doc(filter_tags, doc_list, get_content)
  rebuild = ENV.fetch("REBUILD_DOC", nil)
  rerun = ENV["RERUN"] || rebuild || false

  filter_tags.call(rebuild, false).sort_by { |tag| Version.version_to_num(tag.first[1..]) }.each do |tag|
    name, commit_sha, tree_sha, ts = tag
    puts "#{name}: #{ts}, #{commit_sha[0, 8]}, #{tree_sha[0, 8]}"

    stag = Version.where(name: name.gsub("v", "l10n")).first_or_create

    next if (stag.commit_sha == commit_sha) && !rerun

    stag.commit_sha = commit_sha
    stag.tree_sha = tree_sha
    stag.committed = ts
    stag.save

    tag_files = doc_list.call(tree_sha)
    doc_files = tag_files.select do |ent|
      ent.first =~
        /^([-_\w]+)\/(
          (
            git.* |
            scalar
        )\.txt)/x
    end

    puts "Found #{doc_files.size} entries"

    get_content_f = proc do |source, target|
      name = File.join(File.dirname(source), target)
      content_file = tag_files.detect { |ent| ent.first == name }
      if content_file
        new_content = get_content.call(content_file[1])
      else
        puts "Included file #{name} was not translated. Processing anyway\n"
      end
      [new_content, name]
    end

    doc_files.each do |entry|
      full_path, sha = entry
      ids = Set.new([])
      lang = File.dirname(full_path)
      path = File.basename(full_path, ".txt")

      file = DocFile.where(name: path).first_or_create

      puts "   build: #{path} for #{lang}"

      content = get_content.call sha
      categories = {}
      expand_l10n(full_path, content, get_content_f, categories)
      content.gsub!(/link:(?:technical\/)?(\S*?)\.html(\#\S*?)?\[(.*?)\]/m, "link:/docs/\\1/#{lang}\\2[\\3]")
      asciidoc = make_asciidoc(content)
      asciidoc_sha = Digest::SHA1.hexdigest(asciidoc.source)
      doc = Doc.where(blob_sha: asciidoc_sha).first_or_create
      if rerun || !doc.plain || !doc.html
        html = asciidoc.render
        html.gsub!(/linkgit:(\S+?)\[(\d+)\]/) do |line|
          x = /^linkgit:(\S+?)\[(\d+)\]/.match(line)
          "<a href='/docs/#{x[1].gsub(/&#x2d;/, '-')}/#{lang}'>#{x[1]}[#{x[2]}]</a>"
        end
        # HTML anchor on hdlist1 (i.e. command options)
        html.gsub!(/<dt class="hdlist1">(.*?)<\/dt>/) do |_m|
          text = $1.tr("^A-Za-z0-9-", "")
          anchor = "#{path}-#{text}"
          # handle anchor collisions by appending -1
          anchor += "-1" while ids.include?(anchor)
          ids.add(anchor)

          "<dt class=\"hdlist1\" id=\"#{anchor}\"> <a class=\"anchor\" href=\"##{anchor}\"></a>#{$1} </dt>"
        end
        doc.plain = asciidoc.source
        doc.html  = html
        doc.save
      end
      dv = DocVersion.where(version_id: stag.id, doc_file_id: file.id, language: lang).first_or_create
      dv.doc_id = doc.id
      dv.language = lang
      dv.save
    end
  end
end

def drop_uninteresting_tags(tags)
  # proceed in reverse-chronological order, as we'll pick only the
  # highest-numbered point release for older versions
  ret = []
  tags.reverse_each do |tag|
    numeric = Version.version_to_num(tag.first[1..])
    # drop anything older than v2.0
    next if numeric < 2_000_000

    # older than v2.17, take only the highest release
    if (numeric < 2_170_000) && !ret.empty?
      old = Version.version_to_num(ret[0].first[1..])
      next if old.to_i.div(10_000) == numeric.to_i.div(10_000)
    end
    # keep everything else
    ret.unshift(tag)
  end
  ret
end

def expand_content(content, path, get_f_content, generated)
  content.gsub(/include::(\S+)\.txt\[\]/) do |_line|
    if File.dirname(path) == "."
      new_fname = "#{$1}.txt"
    else
      new_fname = (Pathname.new(path).dirname + Pathname.new("#{$1}.txt")).cleanpath.to_s
    end
    if generated[new_fname]
      new_content = generated[new_fname]
    else
      new_content = get_f_content.call(new_fname)
      if new_content
        new_content = expand_content(new_content.force_encoding("UTF-8"),
                                     new_fname, get_f_content, generated)
      else
        puts "#{new_fname} could not be resolved for expansion"
      end
    end
    new_content
  end
end

# returns an array of the differences with 3 entries
# 0: additions
# 1: subtractions
# 2: 8 - (add + sub)
def diff(pre, post)
  diff_out = Diffy::Diff.new(pre, post)
  first_chars = diff_out.to_s.gsub(/(.)[^\n]*\n/, '\1')
  adds = first_chars.count("+")
  mins = first_chars.count("-")
  total = mins + adds
  if total > 8
    min = (8.0 / total)
    adds = (adds * min).round
    mins = (mins * min).round
    total = 8
  end
  [adds, mins, 8 - total]
rescue StandardError
  [0, 0, 8]
end

def index_doc(filter_tags, doc_list, get_content)
  rebuild = ENV.fetch("REBUILD_DOC", nil)
  rerun = ENV["RERUN"] || rebuild || false

  data = read_data

  tags = filter_tags.call(rebuild).sort_by { |tag| Version.version_to_num(tag.first[1..]) }
  drop_uninteresting_tags(tags).each do |tag|
    tagname, commit_sha, tree_sha, ts = tag
    puts "#{tagname}: #{ts}, #{commit_sha[0, 8]}, #{tree_sha[0, 8]}"

    version = tagname.tr("v", "")
    next if data["versions"][version] && !rerun

    data["versions"][version] = version_data = {}

    version_data["commit_sha"] = commit_sha
    version_data["tree_sha"] = tree_sha
    version_data["committed"] = ts
    version_data["date"] = ts.strftime("%m/%d/%y")

    tag_files = doc_list.call(tree_sha)
    doc_files = tag_files.select do |ent|
      ent.first =~
        /^Documentation\/(
          SubmittingPatches |
          MyFirstContribution.txt |
          MyFirstObjectWalk.txt |
          (
            git.* |
            everyday |
            howto-index |
            user-manual |
            diff.* |
            fetch.* |
            merge.* |
            rev.* |
            pretty.* |
            pull.* |
            scalar |
            technical\/.*
        )\.txt)$/x
    end

    puts "Found #{doc_files.size} entries"
    doc_limit = ENV.fetch("ONLY_BUILD_DOC", nil)

    # generate command-list content
    generated = {}
    cmd = tag_files.detect { |f| f.first == "command-list.txt" }
    if cmd
      cmd_list =
        get_content
        .call(cmd[1])
        .match(/(### command list.*|# command name.*)/m)[0]
        .split("\n")
        .grep_v(/^#/)
        .each_with_object({}) do |cmd, list|
          name, kind, attr = cmd.split(/\s+/)
          list[kind] ||= []
          list[kind] << [name, attr]
        end
      generated = cmd_list.keys.inject({}) do |list, category|
        links = cmd_list[category].map do |cmd, attr|
          cmd_file = tag_files.detect { |ent| ent.first == "Documentation/#{cmd}.txt" }
          next unless cmd_file

          content = get_content.call(cmd_file[1])
          section = content.match(/^[a-z0-9-]+\(([1-9])\)/)[1]
          match = content.match(/NAME\n----\n\S+ - (.*)$/)
          if match
            "linkgit:#{cmd}[#{section}]::\n\t#{attr == 'deprecated' ? '(deprecated) ' : ''}#{match[1]}\n"
          end
        end
        list.merge!("Documentation/cmds-#{category}.txt" => links.compact.join("\n"))
      end

      tools = tag_files.select { |ent| ent.first =~ /^mergetools\// }.map do |entry|
        path, sha = entry
        tool = File.basename path
        content = get_content.call sha
        merge = content.include?("can_merge") ? "" : " * #{tool}\n"
        diff = content.include?("can_diff") ? "" : " * #{tool}\n"
        [merge, diff]
      end

      can_merge, can_diff = tools.transpose.map(&:join)
      generated["Documentation/mergetools-diff.txt"] = can_diff
      generated["Documentation/mergetools-merge.txt"] = can_merge

      get_content_f = proc do |name|
        content_file = tag_files.detect { |ent| ent.first == name }
        if content_file
          new_content = get_content.call(content_file[1])
        end
        new_content
      end

      doc_files.each do |entry|
        path, sha = entry
        ids = Set.new([])
        docname = File.basename(path, ".txt")
        # TEMPORARY: skip the scalar technical doc until it has a non-overlapping name
        next if path == "Documentation/technical/scalar.txt"
        next if doc_limit && path !~ /#{doc_limit}/

        doc_path = "#{SITE_ROOT}content/docs/#{docname}"

        puts "   build: #{docname}"

        data["pages"][docname] = {
          "version-map" => {}
        } unless data["pages"][docname]
        page_data = data["pages"][docname]

        content = expand_content((get_content.call sha).force_encoding("UTF-8"), path, get_content_f, generated)
        # Handle `gitlink:` mistakes (the last of which was fixed in
        # dbf47215e32b (rebase docs: fix "gitlink" typo, 2019-02-27))
        content.gsub!(/gitlink:/, "linkgit:")
        content.gsub!(/link:(?:technical\/)?(\S*?)\.html(\#\S*?)?\[(.*?)\]/m, "link:/docs/\\1\\2[\\3]")

        asciidoc = make_asciidoc(content)
        asciidoc_sha = Digest::SHA1.hexdigest(asciidoc.source)
        if !File.exists?("#{SITE_ROOT}_generated-asciidoc/#{asciidoc_sha}")
          FileUtils.mkdir_p("#{SITE_ROOT}_generated-asciidoc")
          File.open("#{SITE_ROOT}_generated-asciidoc/#{asciidoc_sha}", "w") do |out|
            out.write(content)
          end
        end

        version_map = page_data["version-map"]
        next if !rerun && version_map[version] == asciidoc_sha

        version_map[version] = asciidoc_sha

        # Generate HTML
        html = asciidoc.render
        html.gsub!(/linkgit:+(\S+?)\[(\d+)\]/) do |line|
          x = /^linkgit:+(\S+?)\[(\d+)\]/.match(line)
          relurl = "docs/#{x[1].gsub(/&#x2d;/, '-')}"
          "<a href='{{< relurl \"#{relurl}\" >}}'>#{x[1]}[#{x[2]}]</a>"
        end
        # HTML anchor on hdlist1 (i.e. command options)
        html.gsub!(/<dt class="hdlist1">(.*?)<\/dt>/) do |_m|
          text = $1.tr("^A-Za-z0-9-", "")
          anchor = "#{path}-#{text}"
          # handle anchor collisions by appending -1
          anchor += "-1" while ids.include?(anchor)
          ids.add(anchor)
          "<dt class=\"hdlist1\" id=\"#{anchor}\"> <a class=\"anchor\" href=\"##{anchor}\"></a>#{$1} </dt>"
        end
        # Make links relative
        html.gsub!(/(<a href=['"])\/([^'"]*)/, '\1{{< relurl "\2" >}}')

        doc_versions = version_map.keys.sort{|a, b| Version.version_to_num(a) <=> Version.version_to_num(b)}
        doc_version_index = doc_versions.index(version)

        changed_in = doc_version_index
        changed_in = changed_in - 1 while version_map[doc_versions[changed_in - 1]] == asciidoc_sha
        unchanged_until = doc_version_index
        unchanged_until = unchanged_until + 1 while version_map[doc_versions[unchanged_until + 1]] == asciidoc_sha

        if !page_data["latest-changes"] || Version.version_to_num(page_data["latest-changes"]) <= Version.version_to_num(version)
          page_data["latest-changes"] = doc_versions[changed_in]
        end

        # Write <docname>/<version>.html
        front_matter = {
          "category" => "manual",
          "section" => "documentation",
          "subsection" => "manual",
          "title" => "Git - #{docname} Documentation",
          "docname" => docname,
          "version" => doc_versions[changed_in],
        }

        if changed_in != doc_version_index && File.exists?("#{doc_path}/#{version}.html")
          # remove obsolete file
          File.delete("#{doc_path}/#{version}.html")
        end

        FileUtils.mkdir_p(doc_path)
        front_matter_with_redirects = front_matter.clone
        front_matter_with_redirects["aliases"] =
          doc_versions[changed_in..unchanged_until].flat_map do |v|
            ["/docs/#{docname}/#{v}/index.html"]
          end
        File.open("#{doc_path}/#{doc_versions[changed_in]}.html", "w") do |out|
          out.write("#{front_matter_with_redirects.to_yaml}\n---\n")
          out.write(html)
        end

        # Write <docname>.html
        if page_data["latest-changes"] == version
          FileUtils.mkdir_p(File.dirname(doc_path))
          File.open("#{doc_path}.html", "w") do |out|
            front_matter["latest-changes"] = version
            front_matter["aliases"] = ["/docs/#{docname}/index.html"]
            out.write("#{front_matter.to_yaml}\n---\n")
            out.write(html)
          end
        end

        # Regenerate `page-versions` info
        page_data["page-versions"] = page_versions = [{
          "name" => doc_versions[0],
          "added" => 8,
          "removed" => 0
        }]
        i = 1
        while i < doc_versions.length do
          pre_version = doc_versions[i - 1]
          post_version = doc_versions[i]
          pre_sha = version_map[pre_version]
          post_sha = version_map[post_version]
          if pre_sha == post_sha
            # unchanged
            j = i
            j = j + 1 while post_sha == version_map[doc_versions[j + 1]]
            page_versions.unshift({
              "name" => i == j ? post_version : "#{post_version} &rarr; #{doc_versions[j]}"
            })
            i = j + 1
          else
            page_data["diff-cache"] = {} if !page_data["diff-cache"]
            cached_diff = page_data["diff-cache"]["#{pre_sha}..#{post_sha}"]
            if !cached_diff
              pre_content = File.read("#{SITE_ROOT}_generated-asciidoc/#{pre_sha}")
              post_content = File.read("#{SITE_ROOT}_generated-asciidoc/#{post_sha}")
              cached_diff = page_data["diff-cache"]["#{pre_sha}..#{post_sha}"] = diff(pre_content, post_content)
            end
            page_versions.unshift({
              "name" => doc_versions[i],
              "added" => cached_diff[0],
              "removed" => cached_diff[1]
            })
            i = i + 1
          end
        end
      end
    end
    data["latest-version"] = version if !data["latest-version"] || Version.version_to_num(data["latest-version"]) < Version.version_to_num(version)
  end
  File.open(DATA_FILE, "w") do |out|
    YAML.dump(data, out)
  end
end

def github_index_doc(index_fun, repo)
  Octokit.auto_paginate = true
  @octokit = Octokit::Client.new(access_token: ENV.fetch("GITHUB_API_TOKEN", nil))

  repo = ENV["GIT_REPO"] || repo

  blob_content = Hash.new do |blobs, sha|
    content = Base64.decode64(@octokit.blob(repo, sha, encoding: "base64").content)
    blobs[sha] = content.force_encoding("UTF-8")
  end

  tag_filter = lambda do |tagname, gettags = true|
    # find all tags
    if gettags
      tags = @octokit.tags(repo).select { |tag| !tag.nil? && tag.name =~ /v\d([.\d])+$/ } # just get release tags
      if tagname
        tags = tags.select { |t| t.name == tagname }
      end
    else
      tags = [Struct.new(:name).new("HEAD")]
    end
    tags.collect do |tag|
      # extract metadata
      commit_info = @octokit.commit(repo, tag.name)
      commit_sha = commit_info.sha
      tree_sha = commit_info.commit.tree.sha
      # ts = Time.parse( commit_info.commit.committer.date )
      ts = commit_info.commit.committer.date
      [tag.name, commit_sha, tree_sha, ts]
    end
  end

  get_content =   ->(sha) do blob_content[sha] end

  get_file_list = lambda do |tree_sha|
    tree_info = @octokit.tree(repo, tree_sha, recursive: true)
    tree_info.tree.collect { |ent| [ent.path, ent.sha] }
  end

  send(index_fun, tag_filter, get_file_list, get_content)
end

def local_index_doc(index_fun)
  dir = ENV.fetch("GIT_REPO", nil)
  Dir.chdir(dir) do
    tag_filter = lambda do |tagname, gettags = true|
      if gettags
        # find all tags
        tags = `git tag -l --sort=version:refname 'v[12]*'`.strip.split("\n")
        tags = tags.grep(/v\d([.\d])+$/) # just get release tags
        if tagname
          tags = tags.select { |t| t == tagname }
        end
      else
        tags = ["HEAD"]
      end
      tags.collect do |tag|
        # extract metadata
        commit_sha = `git rev-parse #{tag}`.chomp
        tree_sha = `git rev-parse #{tag}^{tree}`.chomp
        tagger = `git cat-file commit #{tag} | grep committer`.chomp.split
        _tz = tagger.pop
        ts = tagger.pop
        ts = Time.at(ts.to_i)
        [tag, commit_sha, tree_sha, ts]
      end
    end

    get_content =   ->(sha) do `git cat-file blob #{sha}` end

    get_file_list = lambda do |tree_sha|
      entries = `git ls-tree -r #{tree_sha}`.strip.split("\n")
      entries.map do |e|
        _mode, _type, sha, path = e.split
        [path, sha]
      end
    end

    send(index_fun, tag_filter, get_file_list, get_content)
  end
end

if ARGV.length == 2
  if ARGV[0] != "remote"
    ENV["GIT_REPO"] = ARGV[0]
    if ARGV[1] != "l10n"
      local_index_doc(:index_doc)
    else
      local_index_doc(:index_l10n_doc)
    end
  else
    if ARGV[1] != "l10n"
      github_index_doc(:index_doc, "gitster/git")
    else
      github_index_doc(:index_l10n_doc, "jnavila/git-html-l10n")
    end
  end
else
  abort("Need two arguments: (<path-to-repo> | remote) (en | l10n)!")
end
