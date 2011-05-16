class CreateUsers < ActiveRecord::Migration
  
  def self.up
    create_table :users do |t|
      
      # Auth
      t.string :email,              :null=>false
      t.string :auth_method,        :null=>false
      t.string :password_hash,      :null=>false
      t.string :password_salt
      t.string :verification_key,   :null=>false
      t.boolean :enabled,           :null=>false, :default=>true
      t.boolean :verified,          :null=>false, :default=>false
      
      # User info
      t.string :name
      t.string :phone
      t.string :position
      t.string :country
      t.string :postcode
      t.date   :date_of_birth
      
      # Profile info
      t.text :profile
      
      # Times etc.
      t.timestamps
      t.datetime :accessed_at
      
      # Other
      t.boolean :mailing_list, :null=>false, :default=>true
      t.string :role, :null=>false, :default=>"USER"
      
    end
    
    add_index :users, :email, :unique => true, :name => "index_users_email"
    add_index :users, [:email, :password_hash, :password_salt, :enabled, :verified, :mailing_list, :role], :name => "index_users_main"
  end

  def self.down
    drop_table :users
  end
  
end
