Factory.define :asset_folder do |f|
  f.sequence(:name) {|n| "Test folder #{n}" }
end