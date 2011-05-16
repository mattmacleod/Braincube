Factory.define :author do |f|
  f.association :article 
  f.association :user
end