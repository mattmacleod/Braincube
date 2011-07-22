class CreatePageWidgets < ActiveRecord::Migration
  def self.up
    create_table :page_widgets do |t|
      t.integer :widget_id, :null => false
      t.integer :page_id, :null => false
      t.string :slot, :null => false
      t.integer :sort_order, :null => false, :default => 0
      t.timestamps
    end
    
    add_index :page_widgets, :page_id
    add_index :page_widgets, :widget_id
    add_index :page_widgets, :slot
    add_index :page_widgets, [:page_id, :widget_id]
  end

  def self.down
    drop_table :page_widgets
  end
end
