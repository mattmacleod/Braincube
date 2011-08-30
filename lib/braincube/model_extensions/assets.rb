module Braincube #:nodoc:
  module ModelExtensions #:nodoc:
    module Assets #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      

      module ClassMethods
        
        def braincube_has_assets(options={})
          
          has_many :asset_links, :as => :item, :order => :sort_order, 
                   :include => :asset, :dependent => :destroy, :inverse_of => :item
          
          has_many :assets, :through => :asset_links
          
          accepts_nested_attributes_for :asset_links, :allow_destroy => true
          attr_accessible :asset_links_attributes
          
          before_save :cache_main_image
          
          include Braincube::ModelExtensions::Assets::InstanceMethods
        
        end

      end


      module InstanceMethods
        
        def main_image_link
          return nil unless asset_links.length > 0
          return asset_links.sort_by(&:sort_order).first
        end
        
        private
        
        def cache_main_image
          return unless respond_to?( :main_image_id )
          self.main_image_id = asset_links.sort_by(&:sort_order).first.asset_id rescue nil
        end
        
      end
      
    end
  end
end
 
ActiveRecord::Base.send(:include, Braincube::ModelExtensions::Assets)
