Factory.define :page_widget do |f|
  f.page { Factory(:page) }
  f.widget { Factory(:widget) }
end