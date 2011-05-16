class CreateSections < ActiveRecord::Migration
  def self.up
    create_table :sections do |t|
      t.string :name, :null=>false
    end
    add_index :sections, :name, :unique=>true
  end

  def self.down
    drop_table :sections
  end
end
