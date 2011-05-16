Factory.define :venue do |f|
  f.sequence(:title) {|n| "Test venue #{n}"}
  f.association :user
end