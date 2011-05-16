module Braincube #:nodoc:
  module ModelExtensions #:nodoc:

    class TagList < Array
  
      def initialize(*args)
        add(*args)
      end

      def add(*names)
        extract_and_apply_options!(names)
        concat(names)
        clean!
        self
      end

      def remove(*names)
        extract_and_apply_options!(names)
        delete_if { |name| names.include?(name) }
        self
      end
  
      def to_s
        clean!
        map{|n| n.include?(",") ? "\"#{n}\"" : n }.join(", ")
      end
  
     private
 
      def clean!
        reject!(&:blank?)
        map!(&:strip)
        uniq!
      end
  
      def extract_and_apply_options!(args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options.assert_valid_keys :parse
    
        if options[:parse]
          args.map! { |a| self.class.from(a) }
        end
    
        args.flatten!
      end
  
      class << self

        def from(string)
          new.tap do |tag_list|
            string = string.to_s.gsub('.', '').dup
        
            string.gsub!(/"(.*?)"\s*,?\s*/) { tag_list << $1; "" }
            string.gsub!(/'(.*?)'\s*,?\s*/) { tag_list << $1; "" }
        
            tag_list.add(string.split(",").uniq)
          end
        end
    
      end
  
    end
  end
end