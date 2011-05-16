class CreateOwners < ActiveRecord::Migration
  def self.up
    create_table :owners, :id=>false do |t|
      t.integer :section_id
      t.integer :user_id
    end
    add_index :owners, [:section_id, :user_id], :unique => true
  end

  def self.down
    drop_table :owners
  end
end
