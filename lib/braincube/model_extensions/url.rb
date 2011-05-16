module Braincube #:nodoc:
  module ModelExtensions #:nodoc:
    module Url #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
            
      module ClassMethods
        
        def braincube_has_url(attribute, options={})
                    
          cattr_accessor :url_source_attribute, :url_attribute
          before_validation :update_url
          
          self.url_source_attribute = options[:generated_from] || "title"
          self.url_attribute = attribute
          
          validates attribute, :presence=>true, :format=>{ :with=>Braincube::Config::UrlRegexp }, :unless => Proc.new { self[self.class.url_source_attribute].blank?  }
          
          include Braincube::ModelExtensions::Url::InstanceMethods
          
        end
                
      end
      

      module InstanceMethods
                
        def update_url
          self[self.class.url_attribute] = 
            Braincube::Util::pretty_url( 
              self.send( self.class.url_source_attribute ).to_s 
            )
        end
        
        def to_param
          return "#{id}-#{self[self.class.url_attribute]}"
        end
        
      end
      
    end
  end
end
 
ActiveRecord::Base.send(:include, Braincube::ModelExtensions::Url)
