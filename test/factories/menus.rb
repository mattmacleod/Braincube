Factory.define :menu do |f|
  f.sequence(:title){ |n| "Test menu #{n}" }
  f.sequence(:domain){ |n| "test#{n}.example.com" }
end