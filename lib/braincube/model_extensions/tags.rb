#Based on Jonathan Vine's acts_as_taggable_on_steroids

module Braincube #:nodoc:
  module ModelExtensions #:nodoc:
    module Tags #:nodoc:
      
      # Get class methods set up
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      
      # Class methods
      ############################################################################
      
      module ClassMethods
        
        def braincube_has_tags(options={})
                    
          has_many  :taggings, :dependent => :destroy, 
                    :include => :tag, :as => :taggable
                    
          has_many  :tags, :through => :taggings

          after_save :save_tags
          
          attr_accessible :tag_list
          
          include Braincube::ModelExtensions::Tags::InstanceMethods
          extend Braincube::ModelExtensions::Tags::SingletonMethods
          
        end
        
      end
      
      
      # Singleton methods
      ############################################################################
      
      module SingletonMethods
        
        # Pass either a tag string, or an array of strings or tags
        def tagged_with_all(tags)
          
          tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
          return where("1=0") if tags.empty?
          
          # This is quite stupid, but we have to work around MySQL's broken
          # subquery optimisations
          tag_query = "(#{ Tag.where( :name => tags ).map(&:id).join(",")})"
          taggable_id_query = Tagging.select(:taggable_id).where(:taggable_type => "Article").where("tag_id IN #{tag_query}").group(:taggable_id).having("COUNT(tag_id)=#{tags.length}").map(&:taggable_id).join(", ")
          
          return where("1=0") if taggable_id_query.empty?
          
          return select("DISTINCT #{table_name}.*").where("#{table_name}.id IN (#{taggable_id_query})")

        end

        def tagged_with_any(tags)

          # Get a list of tags and construct the query string if req'd
          tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
          return where("1=0") if tags.empty?
          tag_query = "(#{ Tag.where( :name => tags ).map(&:id).join(",")})"
          
          # Use a subquery to return all matching items
          return  where("#{table_name}.id IN (SELECT taggable_id FROM taggings WHERE taggable_type = '#{name}' AND tag_id IN #{tag_query})" )

        end

       private
       
       # Build a matcher for each tag
       def tags_condition(tags)
         ids = Tag.where( "tags.name IN (?)", tags ).map(&:id).join(", ")
         ids.blank? ? "1=1" : "(tag_id IN (#{ ids }))"
       end
        
       public
        
      end


      # Instance methods
      ############################################################################
      
      module InstanceMethods
        
        # Get a TagList object
        def tag_list
          @tag_list ||= TagList.new(*tags.map(&:name))
        end
        
        # Set using a string of tags
        def tag_list=(value)
          @tag_list = TagList.from(value)
        end
        
        def related(count = 5)
          return Tagging.select(
            "taggings.taggable_id,taggings.taggable_type").
            where(
            "taggable_id!=#{id} "+
            "AND tag_id IN "+
            "(SELECT tag_id FROM taggings WHERE taggable_type='#{self.class.name}' "+
            " AND taggable_id=#{id}) ").
            group("taggable_id, taggable_type").
            order("COUNT(taggable_id) DESC").
            limit(count)
        end
        
        private 
        
        # Called after save to store the tags
        def save_tags

          # If there are no tags, don't do anything
          return unless @tag_list
          
          # Figure out which tags are new, and which tags need to be removed
          new_tag_names = @tag_list - tags.map(&:name)
          old_tags = tags.reject { |tag| @tag_list.include?(tag.name) }
                    
          # In a transaction, destroy the old tags and make the new ones
          self.class.transaction do
            if old_tags.any?
              old_tags_ids = old_tags.map(&:id)
              taggings.each{|t| t.destroy if old_tags_ids.include? t.tag_id}            
              reload
            end
            
            new_tag_names.each do |new_tag_name|
              tags << Tag.find_or_create(new_tag_name)
            end
          end
          
          # We're good if there was no exception
          return true
          
        end
        
        public
        
      end
    end
  end
end
 
ActiveRecord::Base.send(:include, Braincube::ModelExtensions::Tags)
