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
          tagged_with( tags, true )
        end

        def tagged_with_any(tags)
          tagged_with( tags, false )
        end

        def traditional_tagged_with_all(tags)
          traditional_tagged_with( tags, true )
        end

        def traditional_tagged_with_any(tags)
          traditional_tagged_with( tags, false )
        end

       private
       
       def tagged_with( tags, match_all = false )
         
         tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
         return where("1=0") if tags.blank?
         
         # This is quite stupid, but we have to work around MySQL's broken
         # subquery optimisations by doing them seperately.
         
         # First, get the tag IDs...
         tag_ids = Tag.where( :name => tags ).map(&:id)
         return where("2=0") if tag_ids.blank?
         tag_query = "(#{ tag_ids.join(",") })"

         # If we need to match all tags, then group and limit
         if match_all
					 taggable_ids = Tagging.connection.execute("SELECT GROUP_CONCAT(taggable_id) FROM (SELECT taggable_id FROM taggings WHERE taggable_type='#{ name }' AND tag_id IN #{ tag_query } GROUP BY taggable_id HAVING COUNT(id)=#{tags.length}) AS taggables_with_all_tags").first
         else
           taggable_ids = Tagging.connection.execute("SELECT GROUP_CONCAT(taggable_id) FROM taggings WHERE taggable_type='#{ name }' AND tag_id IN #{ tag_query }").first
         end
         
         #... then build a SQL string ...
         return where("3=0") if taggable_ids.compact.empty?
         
         # ... then find all matching taggables!
         return where("#{table_name}.id IN (#{taggable_ids})")
         
         
       end
        

       def traditional_tagged_with( tags, match_all = false )
         
         tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
         return where("1=0") if tags.blank?
         
				# Get the tag condition
				 tags_condition = tags.map { |t| sanitize_sql(["tags.name LIKE ?", t]) }.join(" OR ")
         tags_condition = "(" + tags_condition + ")"

         # Now the rest...          
         if match_all
					
					 return where(
	         "((SELECT COUNT(*) FROM taggings INNER JOIN tags "+
	         "ON taggings.tag_id = tags.id "+
	         "WHERE taggable_id = #{table_name}.id AND taggable_type = \"#{name}\" "+
	         "AND #{tags_condition}) = #{tags.size})"
					 )
				
				else
          return  select("DISTINCT #{table_name}.*").
                  where("taggable_id = #{table_name}.id AND taggable_type = \"#{name}\" ").
                  where( tags_condition ).
                  joins(:taggings => :tag)
				end

       end

        
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
        
        def related 
          tag_ids = self.taggings.map(&:tag_id)
          return self.class.where("4=0") if tag_ids.blank?
          
          taggable_ids = Tagging.select("taggings.taggable_id, COUNT(tag_id) AS tag_count").where("taggable_id!=#{id}").having("tag_count >= 2").where(:tag_id => tag_ids).where(:taggable_type => self.class.name).group("taggable_id, taggable_type").map(&:taggable_id)
          return self.class.where("5=0") if taggable_ids.blank?
          
          return self.class.where(:id => taggable_ids)
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
