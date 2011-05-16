class CreatePerformances < ActiveRecord::Migration
  def self.up
    create_table :performances do |t|
      
      t.integer :event_id, :null => false
      t.integer :venue_id, :null => false
      t.integer :user_id,  :null => false
      
      t.string :price
      t.string :performer
      
      t.timestamps
      t.datetime :starts_at, :null => false
      t.datetime :ends_at
      
      t.boolean :drop_in, :default => false
      t.string :ticket_type
      
      t.text :notes
      
      t.string :cached_venue_name
      t.string :cached_venue_link
      t.string :cached_city_name
      t.string :cached_event_name
      t.string :cached_event_link
      t.string :cached_description
      
      t.string :affiliate_type
      t.string :affiliate_code
      
    end
    
    add_index :performances, :event_id
    add_index :performances, :venue_id
    add_index :performances, :starts_at
    
  end

  def self.down
    drop_table :performances
  end
end
