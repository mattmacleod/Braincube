Factory.define :publication do |f|
  f.name "Test publication"
  f.date_street Time.utc(2009,02,01)
  f.date_deadline Time.utc(2009,01,01)
end