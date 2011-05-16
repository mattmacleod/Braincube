Factory.define :page do |f|
  f.association :user
  f.title "Test page"
  f.association :menu
  f.sequence(:url) {|n| "test#{n}" }
  f.association :parent, :factory => :root_page
end

Factory.define :root_page, :parent => :page do |f|
  f.parent { nil }
  f.url { "" }
end

