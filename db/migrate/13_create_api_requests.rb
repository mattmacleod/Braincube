class CreateApiRequests < ActiveRecord::Migration
  def self.up
    create_table :api_requests do |t|
      t.integer :api_key_id,  :null=>false
      t.integer :api_version, :null=>false, :default=>0
      t.string  :url,         :null=>false
      t.string  :status,      :null=>false
      t.string  :ip,          :null=>false, :limit => 15
      t.datetime :created_at
    end
    add_index :api_requests, :api_key_id
  end

  def self.down
    drop_table :api_requests
  end
end
