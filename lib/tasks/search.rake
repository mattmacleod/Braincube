namespace :search do
  task :reindex do
    system("rake sunspot:reindex models=Article+Page+Event+Venue")
  end
end