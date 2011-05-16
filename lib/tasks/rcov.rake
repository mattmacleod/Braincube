namespace :test do
  task :rcov do
    rcov_cmd = "rcov --rails -x osx/objc,gems/,spec/ -Iapp,lib test/unit/*.rb test/unit/*/*.rb test/functional/*.rb test/functional/*/*.rb"
    system("#{rcov_cmd}")
    system("open coverage/index.html") if PLATFORM['darwin']
  end
end