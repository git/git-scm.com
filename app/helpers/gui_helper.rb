module GuiHelper

  @@conv = { "Mac" => "mac", "Windows" => "windows", "Linux" => "linux", "Android" => "android", "iOS" => "ios"}

  def platformsToCssClass(platforms)
    platforms.map { |p| @@conv[p] }
  end

end