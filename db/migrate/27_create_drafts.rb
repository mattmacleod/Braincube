class CreateDrafts < ActiveRecord::Migration
  def self.up
    create_table :drafts do |t|
      t.integer :item_id, :null => false
      t.string :item_type, :null => false
      t.integer :user_id, :null => false
      t.integer :user_name, :null => false
      t.text :item_data, :null => false
      t.timestamps
    end
    add_index :drafts, [:item_id, :item_type], :unique => true
  end

  def self.down
    drop_table :drafts
  end
end
