class CreateComments < ActiveRecord::Migration
  
  def self.up
    create_table :comments do |t|
      t.integer :item_id,     :null => false
      t.string  :item_type,   :null => false
      
      t.integer :user_id
      t.string :name,     :null => false
      t.string :email,    :null => false
      t.string :ip,       :null => false
      
      t.text    :content,     :null => false
      t.integer :rating,      :null => false, :default => 0
      
      t.boolean :reported,    :null => false, :default => false
      t.boolean :approved,    :null => false, :default => false
      t.boolean :hidden,      :null => false, :default => false

      t.timestamps
    end
    
    add_index :comments, :user_id
    add_index :comments, [:item_type, :item_id, :hidden, :reported, :approved], :name => "comments_index_main"
  end

  def self.down
    drop_table :comments
  end
  
end
