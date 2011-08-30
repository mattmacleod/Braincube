namespace :braincube do
  task :flush_data_cache do
    File.open("#{Rails.root}/tmp/flush_data_cache.txt", 'w') {|f| f.write( Time::now.to_i ) }
  end  
end