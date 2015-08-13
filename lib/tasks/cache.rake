namespace :cache do
  desc "Warm up the cache"
  task :warm => :environment do
    print "Warming the cache..."
    AdminPolicy.all
    puts "Done."
  end
end
