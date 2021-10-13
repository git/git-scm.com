# frozen_string_literal: true

module GuiHelper

  @@conv = { "Mac" => "mac", "Windows" => "windows", "Linux" => "linux", "Android" => "android", "iOS" => "ios"}

  def platforms_to_css_class(platforms)
    platforms.map { |p| @@conv[p] }
  end

end
