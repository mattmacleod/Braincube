class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|

      t.string :title,        :null => false
      t.string :abstract
      t.string :short_content
      t.text   :content
      
      t.boolean :featured, :null => false, :default => false
      t.integer :review_id
      t.integer :user_id,     :null => false
      
      t.boolean :print,   :null => false, :default => true
      t.boolean :enabled, :null => false, :default => true
      
      t.string :affiliate_type
      t.string :affiliate_code
            
      t.timestamps
      
      t.string :cached_times
      t.string :cached_dates
      t.string :cached_prices
      t.string :cached_venues
      t.string :url,          :null => false
      
    end
    
    add_index :events, [:print, :enabled]
    add_index :events, :review_id
    add_index :events, :url
    add_index :events, :title
    
  end

  def self.down
    drop_table :events
  end
end
