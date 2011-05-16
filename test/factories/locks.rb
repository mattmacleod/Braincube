Factory.define :lock do |f|
  f.association :lockable, :factory => :article
  f.association :user
  f.created_at Time::utc(2010,1,1,9,0)
  f.updated_at Time::utc(2010,1,1,9,0)
end