Factory.define :draft do |f|
  f.item { Factory(:article) }
  f.user { Factory(:user, :name => "test") }
  f.user_name { "test" }
  f.item_data( { :title => "Draft"} )
end