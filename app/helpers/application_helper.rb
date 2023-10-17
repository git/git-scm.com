# frozen_string_literal: true

require "iso8601"

module ApplicationHelper
  def sidebar_link_options(section)
    if (%w[about documentation downloads community].include?(@section) && @section == section) ||
       (%w[ reference book videos external-links
            guis logos].include?(@subsection) && @subsection == section)
      { class: "active" }
    else
      {}
    end
  end

  def latest_version
    @version ||= Version.latest_version
    @version.name
  rescue StandardError
    ""
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
    @version ||= Version.latest_version
    "(" + @version.committed.strftime("%Y-%m-%d") + ")"
  rescue StandardError
    ""
  end

  def latest_relnote_url
    "https://raw.github.com/git/git/master/Documentation/RelNotes/#{latest_version}.txt"
  end

  # Overriding this because we're not using asset pipeline for images,
  # but Jason is using image_tag
  #
  # See https://github.com/rails/rails/blob/6b9a1ac484a4eda1b43aba7ed864952aac743ab9/actionview/lib/action_view/helpers/asset_tag_helper.rb#L180-L219
  def image_tag(image, options = {})
    options = options.symbolize_keys

    options[:src] = "/images/#{image}"

    tag("img", options)
  end
end
