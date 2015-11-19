require 'jettywrapper'

desc 'Run the ci build'
task ci: ['jetty:clean', 'jetty:config'] do
  ENV['environment'] = 'test'
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait] = 90

  Jettywrapper.wrap(jetty_params) do
    # run the tests
    Rake::Task['spec'].invoke
  end
end
