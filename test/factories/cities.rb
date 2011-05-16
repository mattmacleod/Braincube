Factory.define :city do |f|
  f.sequence(:name) {|n| "Test city #{n}" }
end