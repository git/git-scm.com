module GuiHelper

  @@conv = { "Mac" => "mac", "Windows" => "windows", "Linux" => "linux"}

  def platformsToCssClass(platforms)
    platforms.map { |p| @@conv[p] }
  end

end