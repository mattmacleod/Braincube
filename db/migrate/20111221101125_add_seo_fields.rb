class AddSeoFields < ActiveRecord::Migration
  def self.up
		add_column :articles, :seo, :text
		add_column :events, :seo, :text
		add_column :venues, :seo, :text
		add_column :pages, :seo, :text
  end

  def self.down
		remove_column :articles, :seo
		remove_column :events, :seo
		remove_column :venues, :seo
		remove_column :pages, :seo
  end
end
