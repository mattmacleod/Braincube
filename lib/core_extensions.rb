require "csv"

# Core extensions for Braincube
Kernel.class_eval do
  
  def numeric?(object)
    true if Float(object) rescue false
  end
  
  def random_string(len)
    (0..(len-1)).map{ rand(36).to_s(36) }.join
  end
  
end


String.class_eval do
  
  def strip_html
    gsub(/<\/?[^>]*>/, "")
  end
  
  def strip_html_except(allowed=[])
    re = if allowed.any?
      Regexp.new(
        %(<(?!(\\s|\\/)*(#{
          allowed.map {|tag| Regexp.escape( tag )}.join( "|" )
        })( |>|\\/|'|"|<|\\s*\\z))[^>]*(>+|\\s*\\z)),
        Regexp::IGNORECASE | Regexp::MULTILINE, 'u'
      )
    else
      /<[^>]*(>+|\s*\z)/m
    end
    gsub(re,'')
  end

  def tagify
    return self.downcase.gsub(/\s/, "+")
  end
  
  def untagify
    return self.gsub("+", " ")
  end
  
  def word_count
    strip_html.split(/\s/).length
  end
  
  
  def truncate_words(count)
    truncated_text = self.split[0..(count-1)].join(" ")
    return (truncated_text == self.chomp) ? self : (truncated_text+"...")
  end
  
end

Array.class_eval do
    
  # Returns a CSV string representing this array. Can specify which columns to
  # include in the serialization by using +options[:columns]+
  #
  # Will attempt to access the +default_export_columns+ class variable on the
  # first entry in the array and use that to calculate export columns. If this
  # is not available, will fall back to outputting all ActiveRecord columns,
  # or fail entirely to do anything.
  def to_csv( options={} )
    
    # What columns do we want to export?
    if options[:columns].blank?
      
      # Try the default export columns
      if (first && first.class.respond_to?( :default_export_columns ))
        options[:columns] ||= first.class.default_export_columns
      end
      
      # Try to access ActiveRecord columns
      return unless first.class.respond_to?( :column_names )
      options[:columns] ||= first.class.column_names.map{|c| [c.humanize, c]}
      
    end
    
    # Build the CSV export
    return CSV.generate do |csv|
      
      # Add the row titles (first array entry)
      csv << options[:columns].map(&:first)
      
      # Add each row. If the content is a symbol, call that method. If it's a 
      # proc, call the proc with the context of the instance. Otherwise, 
      # output the data directly.
      self.each do |item|
        csv << options[:columns].map(&:last).map do |column|
          if column.is_a?( Symbol ) 
            item.send(column)
          elsif column.is_a?( Proc)
            column.call( item )
          else
            column
          end
        end
      end
      
    end
    
  end
  
  
  
  def map_with_index!
    each_with_index do |e, idx| self[idx] = yield(e, idx); end
  end

  def map_with_index(&block)
    dup.map_with_index!(&block)
  end
  
end