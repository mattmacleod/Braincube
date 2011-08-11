class ActiveSupport::TestCase

  class << self
    
    
    
    def should_have_braincube_url(target_attribute = :url, options = {})
      options[:generated_from] ? generated_from = options[:generated_from] : generated_from = "title"
      klass = self.name.gsub(/Test$/, '').underscore.to_sym
      
      context "an existing item" do
        setup { @item = Factory(klass) }

        should "update url field when source attribute is changed" do
          @item[generated_from] = "This is å néw nåmê ø!"
          @item.save!
          assert_equal "this_a_new_name_o", @item.send(target_attribute)
        end
        
        should "limit length of url field when source attribute is changed" do
          @item[generated_from] = "This is a very long title and parts of it should be chopped out after this"
          @item.save!
          assert_equal "this_a_very_long_title_parts_it_should_chopped_out", @item.send(target_attribute)
        end
        
        should "respond to to_param method" do
          assert_equal("#{@item.id}-#{@item.send(target_attribute)}", @item.send(:to_param))
        end
        
      end
    end
  
  
  
  
  
    def should_have_braincube_tags
      should have_many :tags
      should have_many :taggings
      
      klassname = self.name.gsub(/Test$/, '').underscore.to_sym
      klass = Kernel.const_get(self.name.gsub(/Test$/, ''))
      
      context "existing items" do
        setup do
          @items = [
            @item1 = Factory(klassname),
            @item2 = Factory(klassname),
            @item3 = Factory(klassname),
            @item4 = Factory(klassname)
            ]
          @item1.tag_list = "Tag 1, Tag 2, Tag 3"
          @item2.tag_list = "Tag 2, Tag 3, Tag 4"
          @item3.tag_list = "Tag 1, Tag 4, Tag 5"
          @item4.tag_list = "Tag 6, Tag 7, Tag 8"
          @items.each(&:save!)
        end
        
        should "be found by tags" do
          assert_equal [@item3], klass.tagged_with_all("Tag 5").all
        end
        should "only be found when all tags match" do
          assert_equal [@item1, @item2], klass.tagged_with_all(["Tag 2", "Tag 3"]).all
          assert_equal [@item3], klass.tagged_with_all(["Tag 5", "Tag 4", "Tag 1"]).all
        end
        should "only be found when any tags match" do
          assert_equal [@item1, @item3], klass.tagged_with_any(["Tag 1"]).all
          assert_equal [@item1, @item2, @item3], klass.tagged_with_any(["Tag 1", "Tag 2"]).all
        end
        should "have related items" do
          assert_same_elements [@item2, @item3], @item1.related.map(&:taggable)
        end
        should "limit related item count" do
          assert_same_elements [@item2], @item1.related(1).map(&:taggable)
        end
        should "order related items by tag count" do
          assert_equal [@item2, @item3], @item1.related.map(&:taggable)
        end
        context "when tags are replaced" do
          setup do
            @item1.update_attribute(:tag_list, "Tag 2, Tag 99, Tag 100")
          end
          should "add new tags and remove old tags" do
            assert_equal ["Tag 2", "Tag 99", "Tag 100"], @item1.tag_list
            assert_equal 3, @item1.tags.length
          end
          should "not remove old tag objects" do
            assert_equal 10, Tag.count
          end
        end
        context "have tag lists that" do
          should "be able to have single items removed" do
            assert_equal "Tag 1, Tag 2", @item1.tag_list.remove("Tag 3").to_s
          end
          should "be able to have multiple items removed" do
            assert_equal "Tag 3", @item1.tag_list.remove("Tag 1, Tag 2", :parse => true).to_s
          end
        end
      end
      
    end
  
  
  
  
    def should_have_braincube_comments
      should have_many :comments
      klass = self.name.gsub(/Test$/, '').underscore.to_sym
      
      context "an existing item with a comment" do
        setup { @item = Factory(klass); @comment = Factory(:comment, :item => @item) }

        should "have the correct comment count" do
         assert_equal 1, @item.comment_count
        end
      end
      
    end
    
    
    
    
    def should_have_braincube_lock
      should have_one :lock
      klass = self.name.gsub(/Test$/, '').underscore.to_sym
      
      context "an unlocked item" do
        setup { @item = Factory(klass) }
        should "respond false to the locked? method" do
          assert !@item.locked?
          assert_nil @item.lock
        end
        should "be able to be locked" do
          @lock = @item.lock! @user=Factory(:user)
          assert_instance_of Lock, @lock
          assert_equal @user, @lock.user
          assert_equal @item, @lock.lockable
        end
        should "ignore unlock request" do
          assert @item.unlock!
        end
      end
      
      context "a locked item" do
        setup { @item = Factory(klass); @lock = Factory(:lock, :lockable => @item, :updated_at => 1.minute.ago ) }
        should "respond true to the locked? method" do
          assert @item.locked?
          assert_equal @lock, @item.lock
        end
        should "not be able to be locked" do
          @lock = @item.lock!( Factory(:user) )
          assert_nil @lock
        end
        should "be able to be unlocked" do
          assert @item.unlock!
        end
      end
      
    end
    
    
    
    def should_have_braincube_assets
      should have_many :asset_links
      should have_many(:assets).through(:asset_links)
            
      klass = self.name.gsub(/Test$/, '').underscore.to_sym
      
      context "an existing item" do
        setup { @item = Factory(klass) }
        should "not have a main image" do
          assert_nil @item.main_image_link
        end
        context "with two assets" do
          setup do
            @al1=Factory(:asset_link, :item => @item, :asset=>@a2=Factory(:asset), :sort_order => 1)
            @al2=Factory(:asset_link, :item => @item, :asset=>@a1=Factory(:asset), :sort_order => 2)
          end
          should "return the correct main image" do
            assert_equal @al1, @item.main_image_link
          end
        end
      end
    end
    
    
    
    def should_have_braincube_versions
      should have_many :versions
    end
    
    
    
    
    
    def should_have_braincube_properties
      
      klass = self.name.gsub(/Test$/, '').underscore.to_sym
      
      context "an item" do
        setup { @item = Factory(klass) }
        should "have a blank properties hash" do
          assert_equal({}, @item.properties)
        end
        context "when properties are set" do
          setup { @item.properties = {:test => "test" }; @item.save; @item.reload }
          should "return the requested properties" do
            assert @item.properties.is_a? Hash
            assert_equal "test", @item.properties[:test]
          end
          context "and set again" do
            setup { @item.properties = {:test => "new" }; @item.save; @item.reload }
            should "be changed" do
              assert_equal "new", @item.properties[:test]
            end
          end
          context "and set again with different properties" do
            setup { @item.properties = {:another => "another" }; @item.save; @item.reload }
            should "remove old properties" do
              assert_nil @item.properties[:test]
            end
          end
        end
      end
      
    end
      
  end
  
end