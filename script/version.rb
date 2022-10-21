#!/usr/bin/env ruby

class Version
  def self.version_to_num(version)
    version_int = 0.0
    mult = 1_000_000
    numbers = version.to_s.split(".")
    numbers.each do |x|
      version_int += x.to_f * mult
      mult /= 100.0
    end
    version_int
  end
end
