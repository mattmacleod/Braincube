module Braincube
  
  require "iconv"
  
  class Util
    
    # Turns a string into a nice, pretty URL
    def self.pretty_url(string)
      str_src = Iconv.iconv('ascii//ignore//translit', 'utf-8', string.to_s.downcase) rescue string.to_s.downcase
      return  str_src.
              to_s.
              gsub(/(\s+(and|or|the|go|at|be|to|as|at|is|it|an|of|on|a)\s+)+/, " ").
              gsub(/[^A-Za-z0-9\s]/, "").
              gsub(/\s+/, "_").
              gsub(/\_+/, "_").
              chomp("_").
              split("_")[0,10].
              join("_").downcase
    end
    
  end

end