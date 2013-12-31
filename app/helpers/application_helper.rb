module ApplicationHelper

  def sidebar_link_options(section)
    if %w( about documentation reference book blog videos
           external-links downloads guis logos community
          ).include?(@section) && @section == section
      {class: "active"}
    else
      {}
    end
  end

  def partial(part)
    render part
  end

  def random_tagline
    content_tag(:em, '-' * 2) + TAGLINES.sample
  end

  def latest_version
    @version ||= Version.latest_version
    @version.name
  end

  def latest_mac_installer
    @mac_installer ||= Download.latest_for 'mac'
    @mac_installer.version.name
  end

  def latest_win_installer
    @win_installer ||= Download.latest_for 'windows'
    @win_installer.version.name
  end

  def latest_release_date
    @version ||= Version.latest_version
    '(' + @version.committed.strftime("%Y-%m-%d") + ')'
  end

  def latest_relnote_url
    "https://raw.github.com/git/git/master/Documentation/RelNotes/#{self.latest_version}.txt"
  end

  # overriding this because we're not using asset pipeline for images,
  # but jason is using image_tag
  def image_tag(image, options = {})
    out = "<img src='/images/" + image + "'"
    out += " width='" + options[:width].to_s + "'" if options[:width]
    out += " height='" + options[:height].to_s + "'" if options[:height]
    out += " />"
    raw out
  end

end
