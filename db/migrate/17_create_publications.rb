class CreatePublications < ActiveRecord::Migration
  def self.up
    create_table :publications do |t|
      t.string :name, :null=>false
      t.date  :date_street, :null=>false
      t.date  :date_deadline, :null=>false
    end
  end

  def self.down
    drop_table :publications
  end
end
