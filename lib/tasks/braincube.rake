namespace :braincube do
  task :flush_structure do
    `curl http://localhost/api/flush_pages`
  end  
end