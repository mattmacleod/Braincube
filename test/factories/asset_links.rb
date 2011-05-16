Factory.define :asset_link do |f|
  f.item { Factory(:article) }
  f.asset { Factory(:asset) }
end