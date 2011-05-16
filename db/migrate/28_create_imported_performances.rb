class CreateImportedPerformances < ActiveRecord::Migration
  def self.up
    create_table :imported_performances do |t|
      t.timestamps
    end
    
    add_column :imported_performances, :event_name, :string
    add_column :imported_performances, :event_id, :string
    
    add_column :imported_performances, :performer_name, :string
    add_column :imported_performances, :short_description, :string
    add_column :imported_performances, :long_description, :text
    
    add_column :imported_performances, :venue_name, :string
    add_column :imported_performances, :venue_id, :integer
    
    add_column :imported_performances, :city_name, :string
    add_column :imported_performances, :city_id, :string
    
    add_column :imported_performances, :price, :string
    
    add_column :imported_performances, :start_date, :string
    add_column :imported_performances, :end_date, :string
    add_column :imported_performances, :start_time, :string
    add_column :imported_performances, :end_time, :string
    add_column :imported_performances, :parsed_start, :datetime
    add_column :imported_performances, :parsed_end, :datetime
    
    add_column :imported_performances, :ticket_type, :string
    add_column :imported_performances, :category, :string
    add_column :imported_performances, :keywords, :string
    add_column :imported_performances, :notes, :string
    
    add_column :imported_performances, :featured, :boolean
        
  end

  def self.down
    drop_table :imported_performances
  end
end
