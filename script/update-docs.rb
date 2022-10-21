# frozen_string_literal: true

require "asciidoctor"
require "octokit"
require "time"
require "digest/sha1"
require "set"

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
  ActiveRecord::Base.logger.level = Logger::WARN
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
        new_content = get_content.call(content_file.second)
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
        html.gsub!(/linkgit:(\S+)\[(\d+)\]/) do |line|
          x = /^linkgit:(\S+)\[(\d+)\]/.match(line)
          "<a href='/docs/#{x[1]}/#{lang}'>#{x[1]}[#{x[2]}]</a>"
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

def index_doc(filter_tags, doc_list, get_content)
  ActiveRecord::Base.logger.level = Logger::WARN
  rebuild = ENV.fetch("REBUILD_DOC", nil)
  rerun = ENV["RERUN"] || rebuild || false

  tags = filter_tags.call(rebuild).sort_by { |tag| Version.version_to_num(tag.first[1..]) }
  drop_uninteresting_tags(tags).each do |tag|
    name, commit_sha, tree_sha, ts = tag
    puts "#{name}: #{ts}, #{commit_sha[0, 8]}, #{tree_sha[0, 8]}"

    stag = Version.where(name: name.delete("v")).first
    next if stag && !rerun

    stag = Version.where(name: name.delete("v")).first_or_create

    stag.commit_sha = commit_sha
    stag.tree_sha = tree_sha
    stag.committed = ts
    stag.save

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
        )\.txt)/x
    end

    puts "Found #{doc_files.size} entries"
    doc_limit = ENV.fetch("ONLY_BUILD_DOC", nil)

    # generate command-list content
    generated = {}
    cmd = tag_files.detect { |f| f.first == "command-list.txt" }
    if cmd
      cmd_list =
        get_content
        .call(cmd.second)
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

          content = get_content.call(cmd_file.second)
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
          new_content = get_content.call(content_file.second)
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

        file = DocFile.where(name: docname).first_or_create

        puts "   build: #{docname}"

        content = expand_content((get_content.call sha).force_encoding("UTF-8"), path, get_content_f, generated)
        content.gsub!(/link:(?:technical\/)?(\S*?)\.html(\#\S*?)?\[(.*?)\]/m, "link:/docs/\\1\\2[\\3]")
        asciidoc = make_asciidoc(content)
        asciidoc_sha = Digest::SHA1.hexdigest(asciidoc.source)
        doc = Doc.where(blob_sha: asciidoc_sha).first_or_create
        if rerun || !doc.plain || !doc.html
          html = asciidoc.render
          html.gsub!(/linkgit:(\S+)\[(\d+)\]/) do |line|
            x = /^linkgit:(\S+)\[(\d+)\]/.match(line)
            "<a href='/docs/#{x[1]}'>#{x[1]}[#{x[2]}]</a>"
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
        dv = DocVersion.where(version_id: stag.id, doc_file_id: file.id, language: "en").first_or_create
        dv.doc_id = doc.id
        dv.language = "en"
        dv.save
      end

    end
    Rails.cache.write("latest-version", Version.latest_version.name)
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
        tags = `git tag | egrep 'v1|v2'`.strip.split("\n")
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

task local_index: :environment do
  local_index_doc(:index_doc)
end

task local_index_l10n: :environment do
  local_index_doc(:index_l10n_doc)
end

task preindex: :environment do
  github_index_doc(:index_doc, "gitster/git")
end

task preindex_l10n: :environment do
  github_index_doc(:index_l10n_doc, "jnavila/git-html-l10n")
end
