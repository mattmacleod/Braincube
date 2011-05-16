class CreateArticlesEvents < ActiveRecord::Migration
  def self.up
    create_table :articles_events, :id=>false do |t|
      t.integer :article_id
      t.integer :event_id
    end
    add_index :articles_events, [:article_id, :event_id], :unique=>true
  end

  def self.down
    drop_table :articles_events
  end
end
