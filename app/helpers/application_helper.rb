# frozen_string_literal: true

require "iso8601"

module ApplicationHelper

  def sidebar_link_options(section)
    if %w( about documentation downloads community
         ).include?(@section) && @section == section ||
       %w( reference book videos external-links
           guis logos
         ).include?(@subsection) && @subsection == section
      {class: "active"}
    else
      {}
    end
  end

  def random_tagline
    content_tag(:em, "-" * 2) + Gitscm::TAGLINES.sample
  end

  def latest_version
    begin
    @version ||= Version.latest_version
    @version.name
    rescue
      ""
    end
  end

  def latest_mac_installer
    @mac_installer ||= Download.latest_for "mac"
    @mac_installer ? @mac_installer.version.name : ""
  end

  def latest_win_installer
    @win_installer ||= Download.latest_for "windows32"
    @win_installer ? @win_installer.version.name : ""
  end

  def latest_release_date
    begin
    @version ||= Version.latest_version
    "(" + @version.committed.strftime("%Y-%m-%d") + ")"
    rescue
      ""
    end
  end

  def latest_relnote_url
    "https://raw.github.com/git/git/master/Documentation/RelNotes/#{self.latest_version}.txt"
  end

  # Overriding this because we're not using asset pipeline for images,
  # but Jason is using image_tag
  #
  # See https://github.com/rails/rails/blob/6b9a1ac484a4eda1b43aba7ed864952aac743ab9/actionview/lib/action_view/helpers/asset_tag_helper.rb#L180-L219
  def image_tag(image, options = {})
    options = options.symbolize_keys

    src = options[:src] = "/images/#{image}"

    unless src =~ /^(?:cid|data):/ || src.blank?
      options[:alt] = options.fetch(:alt) { image_alt(src) }
    end

    tag("img", options)
  end

  def banner_duration(duration)
    return "" unless duration.present?
    ISO8601::Duration.new(duration).to_seconds.round * 1000
  end
end
