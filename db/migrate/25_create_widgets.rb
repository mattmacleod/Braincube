class CreateWidgets < ActiveRecord::Migration
  def self.up
    create_table :widgets do |t|
      t.string :title, :null => false
      t.string :widget_type, :null => false
      t.text :properties, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :widgets
  end
end
