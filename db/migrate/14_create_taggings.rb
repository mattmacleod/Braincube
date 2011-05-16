class CreateTaggings < ActiveRecord::Migration
  def self.up
    create_table :taggings do |t|
      t.integer :taggable_id,  :null=>false
      t.integer :tag_id,       :null=>false
      t.string :taggable_type, :null=>false
    end
    add_index :taggings, [:tag_id, :taggable_type, :taggable_id], :unique=>true, :name => "tagging_index"
    add_index :taggings, [:tag_id], :unique=>false
    add_index :taggings, [:taggable_type, :taggable_id], :unique=>false
    
  end

  def self.down
    drop_table :taggings
  end
end
