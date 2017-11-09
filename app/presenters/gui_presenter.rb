class GuiPresenter

  def read_gui_yaml
    yaml = YAML.load_file('resources/guis.yml')
    return yaml["guis"]
  end

  def initialize
    @guis_info = read_gui_yaml
  end

  @@instance = GuiPresenter.new

  def self.instance
    return @@instance
  end

  def guis_info
    if Rails.env.production?
      return @guis_info
    else
      return read_gui_yaml
    end
  end

  private_class_method :new
  private :read_gui_yaml
end
