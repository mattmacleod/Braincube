class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      
      t.string  :url,        :null => false
      t.string  :page_type,  :null => false, :default => "TEXT"
      t.integer :user_id,    :null => false
      
      t.string  :title,      :null => false
      t.text    :abstract
      t.text    :content
       
      t.timestamps
      t.datetime  :starts_at
      t.datetime  :ends_at
      
      t.text    :properties
      t.integer :parent_id
      t.integer :menu_id,     :null => false
      t.integer :sort_order,  :default => 0, :null => false
      t.boolean :enabled,     :null => false, :default => true
      t.boolean :show_on_main_menu, :null => false, :default => true
    end
    
    add_index :pages, [:url, :menu_id], :unique => true
    add_index :pages, [:parent_id, :menu_id, :starts_at, :ends_at, :enabled], :name => "page_index"
    
  end

  def self.down
    drop_table :pages
  end
end
