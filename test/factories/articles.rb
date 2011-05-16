Factory.define :article do |f|
  f.title "Test article"
  f.association :section
  f.association :user
end