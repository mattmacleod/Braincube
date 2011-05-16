class CreateMenus < ActiveRecord::Migration
  
  def self.up
    create_table :menus do |t|
      t.string  :title, :null => false
      t.string  :domain, :null => false
      t.timestamps
    end
    
    add_index :menus, :title, :unique => true
    add_index :menus, :domain, :unique => true
    
  end

  def self.down
    drop_table :menus
  end
  
end
