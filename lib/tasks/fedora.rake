namespace :fedora do
  desc 'Cleans the ActiveFedora repository'
  task clean: [:environment] do
    if Rails.env.production? && !ENV['DO_IT'].to_s.casecmp('true').zero?
      puts 'Failsafe: refusing to clean Fedora when RAILS_ENV=production'
      puts
      puts 'If you really want to do this, run:'
      puts '  DO_IT=true RAILS_ENV=production rake fedora:clean'
    else
      require 'active_fedora/cleaner'
      puts "Cleaning Fedora via 'ActiveFedora.Cleaner.clean!' ..."
      ActiveFedora::Cleaner.clean!
      puts 'Finished'
    end
  end
end
