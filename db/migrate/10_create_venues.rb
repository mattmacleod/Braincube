class CreateVenues < ActiveRecord::Migration
  def self.up
    create_table :venues do |t|
      
      t.string :title, :null => false
      t.string :address_1
      t.string :address_2
      t.integer :city_id
      t.string :postcode
      t.string :phone
      t.string :email
      t.string :web
      
      t.string :abstract
      t.text :content
      
      t.integer :user_id,     :null => false
      t.boolean :featured,    :null => false, :default => false
      t.boolean :enabled,     :null => false, :default => true

      t.string :url,          :null => false
      
      t.float :lat
      t.float :lng
      
      t.text :opening_hours
      
      t.timestamps
    end
    
    add_index :venues, :city_id
    add_index :venues, [:featured, :enabled]
    add_index :venues, [:lat, :lng]
    add_index :venues, :url
    
  end

  def self.down
    drop_table :venues
  end
end
