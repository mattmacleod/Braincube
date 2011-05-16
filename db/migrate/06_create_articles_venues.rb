class CreateArticlesVenues < ActiveRecord::Migration
  def self.up
    create_table :articles_venues, :id=>false do |t|
      t.integer :article_id
      t.integer :venue_id
    end
    add_index :articles_venues, [:article_id, :venue_id], :unique=>true
  end

  def self.down
    drop_table :articles_venues
  end
end
