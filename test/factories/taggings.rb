Factory.define :tagging do |f|
  f.association :taggable, :factory=>:article
  f.taggable_type "Article"
  f.association :tag
end