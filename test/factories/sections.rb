Factory.define :section do |f|
  f.sequence(:name){ |n| "Test section #{n}" }
end