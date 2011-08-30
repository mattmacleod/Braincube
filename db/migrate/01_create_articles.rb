class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      
      # Content items
      t.string  :title,         :null=>false
      t.string  :abstract
      t.text    :standfirst
      t.text    :pullquote
      t.text    :content
      t.text    :footnote
      t.string  :web_address
      
      # Status items
      t.string  :status,        :null=>false,    :default=>"NEW"
      t.boolean :featured,      :null=>false,    :default=>true
      t.boolean :print_only,    :null=>false,    :default=>false
      t.string  :template,      :null=>false,    :default=>"Normal"
      t.string  :article_type,  :null=>false,    :default=>"Article"
      
      # Statistics
      t.integer :word_count,    :null=>false,    :default=>0
      
      # Timestamps
      t.timestamps
      t.datetime :starts_at
      t.datetime :ends_at
      
      # Braincube
      t.integer :section_id,    :null=>false
      t.integer :user_id,       :null=>false
      t.text    :private_notes
      t.integer :publication_id
      
      # Metadata
      t.text    :properties
      t.boolean :review,        :null=>false,     :default=>false
      t.integer :review_rating, :limit=>1
      
      # Caches
      t.string  :cached_authors
      t.string  :cached_tags
      t.string  :main_image_id
      t.string  :url,           :null=>false
      
    end
    
    # Create the indexes
    add_index :articles, [:status, :starts_at, :ends_at, :print_only, :featured], :name=>"index_articles_main"
    add_index :articles, [:review, :review_rating], :name => "index_articles_review"
    add_index :articles, :url, :name => "index_articles_url"
    add_index :articles, :status
    add_index :articles, [:section_id, :publication_id]
    add_index :articles, :updated_at
    
  end

  def self.down
    drop_table :articles
  end
  
end
