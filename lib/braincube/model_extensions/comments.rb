module Braincube #:nodoc:
  module ModelExtensions #:nodoc:
    module Comments #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      
      module ClassMethods
        
        def braincube_has_comments(options={})
          has_many :comments, :as => :item, :dependent => :destroy, :order => :created_at
          include Braincube::ModelExtensions::Comments::InstanceMethods
        end

      end


      module InstanceMethods
        
        def comment_count
          return comments.visible.count
        end
        
      end
      
    end
  end
end
 
ActiveRecord::Base.send(:include, Braincube::ModelExtensions::Comments)
