module Braincube #:nodoc:
  module Export #:nodoc:
               
      def self.included(base)
        base.extend(ClassMethods)
      end
         
      module ClassMethods
        def braincube_set_export_columns( *columns )
          cattr_accessor :default_export_columns
          self.default_export_columns = columns || column_names
          include Braincube::Export::InstanceMethods
        end
      end
      

      module InstanceMethods
        # Overrides ActiveRecord's build-in to_xml method - but only if the 
        # export => true parameter is provided. Then runs our custom
        # builder code to generate nice exportable XML.
        def to_xml( options = {} )

          # Get the columns we want to export. Either the supplied list, or
          # the default list.
          columns = options[:columns] || default_export_columns
          
          # Generate procs for each element we want to export
          export_procs = options[:procs]
          export_procs ||= []
          
          columns.each do |column|
            
            # Get the XML tag name
            tag_name = column[0].to_s.gsub(/\s+/,"_").downcase.dasherize
            
            if column[1].is_a?( Symbol )
              
              # Direct method call - include or method?
              proc = Proc.new do |options, record|
                # Handle hashes
                out = record.send(column[1])
                if out.is_a?(Hash)
                  options[:builder].tag!( tag_name ) do |b|
                    out.each_pair do |key, value|
                      b.tag!(key, value)
                    end
                  end
                else
                  options[:builder].tag!( tag_name, record.send(column[1]) )
                end
              end
              
            elsif column[1].is_a?( Proc )
              
              # A proc we can call
              proc = Proc.new do |options, record|
                options[:builder].tag!( tag_name, column[1].call( record ) )
              end
              
            else
              
              # Something else - build a proc here!
              proc = Proc.new do |options, record|
                options[:builder].tag!( tag_name, column[1] )
              end
              
            end
            
            export_procs << proc
            
          end
          
          # Call the AR to_xml with the only and procs arguments
          super( options.merge!(:only => [nil], :skip_types => true, :procs => export_procs) )
          
        end
        
      end
      
  end
end
 
ActiveRecord::Base.send(:include, Braincube::Export)
