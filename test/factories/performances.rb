Factory.define :performance do |f|
  
  f.association :event
  f.association :venue
  f.association :user
  
  f.starts_at Time::utc(2010,01,01)
  
end