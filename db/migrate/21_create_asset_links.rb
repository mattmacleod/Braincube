class CreateAssetLinks < ActiveRecord::Migration
  
  def self.up
    create_table :asset_links do |t|
      t.integer :item_id,     :null=>false
      t.string  :item_type,   :null=>false
      t.integer :asset_id,    :null=>false
      t.string  :caption
      t.string :url
      t.integer :sort_order,  :null=>false, :default => 0
    end
    add_index :asset_links, [:item_id, :item_type, :asset_id], :unique => true
    add_index :asset_links, [:item_id, :item_type]
    add_index :asset_links, :asset_id
  end

  def self.down
    drop_table :asset_links
  end
  
end
