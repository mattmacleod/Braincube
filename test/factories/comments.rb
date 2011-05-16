Factory.define :comment do |f|
  f.item { Factory(:article) }
  f.content "Test content"
  f.email "test@example.com"
  f.name "Test user"
  f.ip "127.0.0.1"
end