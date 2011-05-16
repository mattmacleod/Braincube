class CreateAuthors < ActiveRecord::Migration
  def self.up
    create_table :authors do |t|
      t.integer     :article_id,  :null => false
      t.integer     :user_id
      t.string      :name
      t.integer     :sort_order,  :null => false, :default => 0
    end
    add_index :authors, :user_id, :unique => false
    add_index :authors, :article_id, :unique => false
    add_index :authors, [:article_id, :user_id], :unique => true 
  end

  def self.down
    drop_table :authors
  end
end
