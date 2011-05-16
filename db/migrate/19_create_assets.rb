class CreateAssets < ActiveRecord::Migration
  
  def self.up
    create_table :assets do |t|
      
      t.integer :asset_folder_id, :null=>false
      t.integer :user_id,         :null=>false
      
      t.string  :title,           :null=>false
      t.text    :caption
      t.string  :credit
      
      t.timestamps
      
      t.string  :asset_file_name,           :null=>false
      t.string  :asset_content_type,        :null=>false
      t.integer :asset_file_size,           :null=>false
      
    end
    add_index :assets, :asset_folder_id
    add_index :assets, :title
  end

  def self.down
    drop_table :assets
  end
  
end
