# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111221101125) do

  create_table "api_keys", :force => true do |t|
    t.string   "code",                            :null => false
    t.string   "name",                            :null => false
    t.string   "permission", :default => "BASIC", :null => false
    t.boolean  "enabled",    :default => true,    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_keys", ["code"], :name => "index_api_keys_on_code", :unique => true

  create_table "api_requests", :force => true do |t|
    t.integer  "api_key_id",                               :null => false
    t.integer  "api_version",               :default => 0, :null => false
    t.string   "url",                                      :null => false
    t.string   "status",                                   :null => false
    t.string   "ip",          :limit => 15,                :null => false
    t.datetime "created_at"
  end

  add_index "api_requests", ["api_key_id"], :name => "index_api_requests_on_api_key_id"

  create_table "articles", :force => true do |t|
    t.string   "title",                                              :null => false
    t.string   "abstract"
    t.text     "standfirst"
    t.text     "pullquote"
    t.text     "content"
    t.text     "footnote"
    t.string   "web_address"
    t.string   "status",                      :default => "NEW",     :null => false
    t.boolean  "featured",                    :default => true,      :null => false
    t.boolean  "print_only",                  :default => false,     :null => false
    t.string   "template",                    :default => "Normal",  :null => false
    t.string   "article_type",                :default => "Article", :null => false
    t.integer  "word_count",                  :default => 0,         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer  "section_id",                                         :null => false
    t.integer  "user_id",                                            :null => false
    t.text     "private_notes"
    t.integer  "publication_id"
    t.text     "properties"
    t.boolean  "review",                      :default => false,     :null => false
    t.integer  "review_rating",  :limit => 1
    t.string   "cached_authors"
    t.string   "cached_tags"
    t.string   "url",                                                :null => false
    t.text     "seo"
  end

  add_index "articles", ["review", "review_rating"], :name => "index_articles_review"
  add_index "articles", ["section_id", "publication_id"], :name => "index_articles_on_section_id_and_publication_id"
  add_index "articles", ["status", "starts_at", "ends_at", "print_only", "featured"], :name => "index_articles_main"
  add_index "articles", ["status"], :name => "index_articles_on_status"
  add_index "articles", ["updated_at"], :name => "index_articles_on_updated_at"
  add_index "articles", ["url"], :name => "index_articles_url"

  create_table "articles_events", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "event_id"
  end

  add_index "articles_events", ["article_id", "event_id"], :name => "index_articles_events_on_article_id_and_event_id", :unique => true

  create_table "articles_venues", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "venue_id"
  end

  add_index "articles_venues", ["article_id", "venue_id"], :name => "index_articles_venues_on_article_id_and_venue_id", :unique => true

  create_table "asset_folders", :force => true do |t|
    t.string  "name",      :null => false
    t.integer "parent_id"
  end

  add_index "asset_folders", ["name", "parent_id"], :name => "index_asset_folders_on_name_and_parent_id", :unique => true
  add_index "asset_folders", ["parent_id"], :name => "index_asset_folders_on_parent_id"

  create_table "asset_links", :force => true do |t|
    t.integer "item_id",                   :null => false
    t.string  "item_type",                 :null => false
    t.integer "asset_id",                  :null => false
    t.string  "caption"
    t.string  "url"
    t.integer "sort_order", :default => 0, :null => false
  end

  add_index "asset_links", ["asset_id"], :name => "index_asset_links_on_asset_id"
  add_index "asset_links", ["item_id", "item_type", "asset_id"], :name => "index_asset_links_on_item_id_and_item_type_and_asset_id", :unique => true
  add_index "asset_links", ["item_id", "item_type"], :name => "index_asset_links_on_item_id_and_item_type"

  create_table "assets", :force => true do |t|
    t.integer  "asset_folder_id",    :null => false
    t.integer  "user_id",            :null => false
    t.string   "title",              :null => false
    t.text     "caption"
    t.string   "credit"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "asset_file_name",    :null => false
    t.string   "asset_content_type", :null => false
    t.integer  "asset_file_size",    :null => false
  end

  add_index "assets", ["asset_folder_id"], :name => "index_assets_on_asset_folder_id"
  add_index "assets", ["title"], :name => "index_assets_on_title"

  create_table "authors", :force => true do |t|
    t.integer "article_id",                :null => false
    t.integer "user_id"
    t.string  "name"
    t.integer "sort_order", :default => 0, :null => false
  end

  add_index "authors", ["article_id", "user_id"], :name => "index_authors_on_article_id_and_user_id", :unique => true
  add_index "authors", ["article_id"], :name => "index_authors_on_article_id"
  add_index "authors", ["user_id"], :name => "index_authors_on_user_id"

  create_table "cities", :force => true do |t|
    t.string   "name",       :null => false
    t.float    "lat"
    t.float    "lng"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cities", ["name"], :name => "index_cities_on_name", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "item_id",                       :null => false
    t.string   "item_type",                     :null => false
    t.integer  "user_id"
    t.string   "name",                          :null => false
    t.string   "email",                         :null => false
    t.string   "ip",                            :null => false
    t.text     "content",                       :null => false
    t.integer  "rating",     :default => 0,     :null => false
    t.boolean  "reported",   :default => false, :null => false
    t.boolean  "approved",   :default => false, :null => false
    t.boolean  "hidden",     :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["item_type", "item_id", "hidden", "reported", "approved"], :name => "comments_index_main"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "drafts", :force => true do |t|
    t.integer  "item_id",    :null => false
    t.string   "item_type",  :null => false
    t.integer  "user_id",    :null => false
    t.integer  "user_name",  :null => false
    t.text     "item_data",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "drafts", ["item_id", "item_type"], :name => "index_drafts_on_item_id_and_item_type", :unique => true

  create_table "events", :force => true do |t|
    t.string   "title",                             :null => false
    t.string   "abstract"
    t.string   "short_content"
    t.text     "content"
    t.boolean  "featured",       :default => false, :null => false
    t.integer  "review_id"
    t.integer  "user_id",                           :null => false
    t.boolean  "print",          :default => true,  :null => false
    t.boolean  "enabled",        :default => true,  :null => false
    t.string   "affiliate_type"
    t.string   "affiliate_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cached_times"
    t.string   "cached_dates"
    t.string   "cached_prices"
    t.string   "cached_venues"
    t.string   "url",                               :null => false
    t.text     "seo"
  end

  add_index "events", ["print", "enabled"], :name => "index_events_on_print_and_enabled"
  add_index "events", ["review_id"], :name => "index_events_on_review_id"
  add_index "events", ["title"], :name => "index_events_on_title"
  add_index "events", ["url"], :name => "index_events_on_url"

  create_table "imported_performances", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "event_name"
    t.string   "event_id"
    t.string   "performer_name"
    t.string   "short_description"
    t.text     "long_description"
    t.string   "venue_name"
    t.integer  "venue_id"
    t.string   "city_name"
    t.string   "city_id"
    t.string   "price"
    t.string   "start_date"
    t.string   "end_date"
    t.string   "start_time"
    t.string   "end_time"
    t.datetime "parsed_start"
    t.datetime "parsed_end"
    t.string   "ticket_type"
    t.string   "category"
    t.string   "keywords"
    t.string   "notes"
    t.boolean  "featured"
  end

  create_table "locks", :force => true do |t|
    t.string   "lockable_type", :null => false
    t.integer  "lockable_id",   :null => false
    t.integer  "user_id",       :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "locks", ["lockable_type", "lockable_id", "user_id"], :name => "index_locks_on_lockable_type_and_lockable_id_and_user_id"
  add_index "locks", ["lockable_type", "lockable_id"], :name => "index_locks_on_lockable_type_and_lockable_id", :unique => true

  create_table "menus", :force => true do |t|
    t.string   "title",      :null => false
    t.string   "domain",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "menus", ["domain"], :name => "index_menus_on_domain", :unique => true
  add_index "menus", ["title"], :name => "index_menus_on_title", :unique => true

  create_table "owners", :id => false, :force => true do |t|
    t.integer "section_id"
    t.integer "user_id"
  end

  add_index "owners", ["section_id", "user_id"], :name => "index_owners_on_section_id_and_user_id", :unique => true

  create_table "page_widgets", :force => true do |t|
    t.integer  "widget_id",                 :null => false
    t.integer  "page_id",                   :null => false
    t.string   "slot",                      :null => false
    t.integer  "sort_order", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "page_widgets", ["page_id"], :name => "index_page_widgets_on_page_id"
  add_index "page_widgets", ["slot"], :name => "index_page_widgets_on_slot"
  add_index "page_widgets", ["widget_id"], :name => "index_page_widgets_on_widget_id"

  create_table "pages", :force => true do |t|
    t.string   "url",                                   :null => false
    t.string   "page_type",         :default => "TEXT", :null => false
    t.integer  "user_id",                               :null => false
    t.string   "title",                                 :null => false
    t.text     "abstract"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.text     "properties"
    t.integer  "parent_id"
    t.integer  "menu_id",                               :null => false
    t.integer  "sort_order",        :default => 0,      :null => false
    t.boolean  "enabled",           :default => true,   :null => false
    t.boolean  "show_on_main_menu", :default => true,   :null => false
    t.text     "seo"
  end

  add_index "pages", ["parent_id", "menu_id", "starts_at", "ends_at", "enabled"], :name => "page_index"
  add_index "pages", ["url", "menu_id"], :name => "index_pages_on_url_and_menu_id", :unique => true

  create_table "performances", :force => true do |t|
    t.integer  "event_id",                              :null => false
    t.integer  "venue_id",                              :null => false
    t.integer  "user_id",                               :null => false
    t.string   "price"
    t.string   "performer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "starts_at",                             :null => false
    t.datetime "ends_at"
    t.boolean  "drop_in",            :default => false
    t.string   "ticket_type"
    t.text     "notes"
    t.string   "cached_venue_name"
    t.string   "cached_venue_link"
    t.string   "cached_city_name"
    t.string   "cached_event_name"
    t.string   "cached_event_link"
    t.string   "cached_description"
    t.string   "affiliate_type"
    t.string   "affiliate_code"
  end

  add_index "performances", ["event_id"], :name => "index_performances_on_event_id"
  add_index "performances", ["starts_at"], :name => "index_performances_on_starts_at"
  add_index "performances", ["venue_id"], :name => "index_performances_on_venue_id"

  create_table "publications", :force => true do |t|
    t.string "name",          :null => false
    t.date   "date_street",   :null => false
    t.date   "date_deadline", :null => false
  end

  create_table "sections", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "sections", ["name"], :name => "index_sections_on_name", :unique => true

  create_table "taggings", :force => true do |t|
    t.integer "taggable_id",   :null => false
    t.integer "tag_id",        :null => false
    t.string  "taggable_type", :null => false
  end

  add_index "taggings", ["tag_id", "taggable_type", "taggable_id"], :name => "tagging_index", :unique => true
  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_type", "taggable_id"], :name => "index_taggings_on_taggable_type_and_taggable_id"

  create_table "tags", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email",                                :null => false
    t.string   "auth_method",                          :null => false
    t.string   "password_hash",                        :null => false
    t.string   "password_salt"
    t.string   "verification_key",                     :null => false
    t.boolean  "enabled",          :default => true,   :null => false
    t.boolean  "verified",         :default => false,  :null => false
    t.string   "name"
    t.string   "phone"
    t.string   "position"
    t.string   "country"
    t.string   "postcode"
    t.date     "date_of_birth"
    t.text     "profile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "accessed_at"
    t.boolean  "mailing_list",     :default => true,   :null => false
    t.string   "role",             :default => "USER", :null => false
  end

  add_index "users", ["email", "password_hash", "password_salt", "enabled", "verified", "mailing_list", "role"], :name => "index_users_main"
  add_index "users", ["email"], :name => "index_users_email", :unique => true

  create_table "venues", :force => true do |t|
    t.string   "title",                            :null => false
    t.string   "address_1"
    t.string   "address_2"
    t.integer  "city_id"
    t.string   "postcode"
    t.string   "phone"
    t.string   "email"
    t.string   "web"
    t.string   "abstract"
    t.text     "content"
    t.integer  "user_id",                          :null => false
    t.boolean  "featured",      :default => false, :null => false
    t.boolean  "enabled",       :default => true,  :null => false
    t.string   "url",                              :null => false
    t.float    "lat"
    t.float    "lng"
    t.text     "opening_hours"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "seo"
  end

  add_index "venues", ["city_id"], :name => "index_venues_on_city_id"
  add_index "venues", ["featured", "enabled"], :name => "index_venues_on_featured_and_enabled"
  add_index "venues", ["lat", "lng"], :name => "index_venues_on_lat_and_lng"
  add_index "venues", ["url"], :name => "index_venues_on_url"

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "widgets", :force => true do |t|
    t.string   "title",       :null => false
    t.string   "widget_type", :null => false
    t.text     "properties",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
