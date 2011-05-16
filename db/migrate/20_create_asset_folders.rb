class CreateAssetFolders < ActiveRecord::Migration
  
  def self.up
    
    create_table :asset_folders do |t|
      t.string :name, :null => false
      t.integer :parent_id
    end
    
    add_index :asset_folders, [:name, :parent_id], :unique => true
    add_index :asset_folders, :parent_id
    
  end

  def self.down
    drop_table :asset_folders
  end
  
end
