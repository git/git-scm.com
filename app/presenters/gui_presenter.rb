# frozen_string_literal: true

class GuiPresenter
  def read_gui_yaml
    yaml = YAML.load_file("resources/guis.yml")
    yaml["guis"]
  end

  def initialize
    @guis_info = read_gui_yaml
  end

  @@instance = GuiPresenter.new

  def self.instance
    @@instance
  end

  def guis_info
    if Rails.env.production?
      @guis_info
    else
      read_gui_yaml
    end
  end

  private_class_method :new
  private :read_gui_yaml
end
