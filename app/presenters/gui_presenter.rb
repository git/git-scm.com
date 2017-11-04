class GuiPresenter

  attr_reader :guis_info

  def initialize
    @yaml = YAML.load_file('resources/guis.yml')
    @guis_info = @yaml["guis"]
  end

  @@instance = GuiPresenter.new

  def self.instance
    return @@instance
  end

  private_class_method :new
end