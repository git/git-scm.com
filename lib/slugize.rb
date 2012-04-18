# encoding: utf-8
# from https://github.com/lolmamut/slugize
class String
  def slugize
    str = self
    separator = '-'
    re_separator = Regexp.escape(separator)
    str = pl2us(str)
    str.gsub!(/ /, separator)
    str.gsub!(/[^\x00-\x7F]+/, '')
    str.gsub!(/[^a-z0-9\-_\+]+/i, separator)
    str.gsub!(/#{re_separator}{2,}/, separator)
    str.gsub!(/^#{re_separator}|#{re_separator}$/, '')
    str
  end
  def pl2us(str)
    str = self.downcase.strip
    chars = {'ą' => 'a', 'ć' => 'c', 'ę' => 'e', 'ł' => 'l', 'ń' => 'n', 'ó' => 'o', 'ś' => 's', 'ź' => 'z', 'ż' => 'z'}
    chars.each do |k,v|
      str.gsub! /#{k}/, "#{v}"
    end
    str
  end
end
