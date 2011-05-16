class CreateApiKeys < ActiveRecord::Migration
  
  def self.up
    create_table :api_keys do |t|
      t.string :code,       :null=>false
      t.string :name,       :null=>false
      t.string :permission, :null=>false, :default=>"BASIC"
      t.boolean :enabled,   :null=>false, :default=>true
      t.timestamps
    end
    add_index :api_keys, :code, :unique => true
  end

  def self.down
    drop_table :api_keys
  end
  
end
