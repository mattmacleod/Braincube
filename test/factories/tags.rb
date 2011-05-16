Factory.define :tag do |f|
  f.sequence(:name) { |n| "Test tag #{n}"}
end