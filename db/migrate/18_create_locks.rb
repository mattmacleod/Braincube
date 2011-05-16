class CreateLocks < ActiveRecord::Migration
  def self.up
    create_table :locks do |t|
      
      t.string :lockable_type, :null => false
      t.integer :lockable_id,  :null => false
      t.integer :user_id,      :null => false

      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
      
    end
    
    add_index :locks, [:lockable_type, :lockable_id, :user_id]
    add_index :locks, [:lockable_type, :lockable_id], :unique => true
    
  end

  def self.down
    drop_table :locks
  end
end
