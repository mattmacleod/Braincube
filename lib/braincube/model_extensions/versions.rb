module Braincube #:nodoc:
  module ModelExtensions #:nodoc:
    module Versions #:nodoc:
          
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      
      module ClassMethods
        
        def braincube_has_versions( *attributes )
          
          has_paper_trail :only => attributes
          has_many :drafts, :as => :item, :dependent => :destroy
          
          include Braincube::ModelExtensions::Versions::InstanceMethods
          
        end

      end
      
      module InstanceMethods
      
        def save_draft( user, data )
          transaction do
            drafts.destroy_all
            drafts.create!( :user => user, :user_name => user.name, :item_data => data ) rescue nil
            return drafts.first
          end
        end
        
        def has_draft?
          !!drafts.first
        end
        
        # There is only one draft
        def load_draft
          return self unless self.drafts.first
          drafts.first.item_data.each_pair do |attribute, value|
            self.send("#{attribute}=", value) rescue nil
          end
          valid? # There's a good reason for this.
          return self
        end
      
      end
      
    end
  end
end
 
ActiveRecord::Base.send(:include, Braincube::ModelExtensions::Versions)
