require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'mina/unicorn'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :user, 'ec2-user'
set :domain, 'dummy'
set :deploy_to, '/data/dummy'
set :repository, 'git@github.com:chickenriceplatter/dummy.git'
set :branch, 'master'

# For system-wide RVM install.
set :rvm_path, '/home/ec2-user/.rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'log', 'tmp/sockets', 'tmp/pids']

set :unicorn_pid, '/var/run/deploy/unicorn.pid'

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use[ruby-2.2.1@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml'."]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'install:bundler'
    invoke :'bundle:install'
    # invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      invoke :'db:migrate'
      invoke :'db:seed'
      queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
      queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
      invoke :'start:unicorn'
    end
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

namespace :start do
  desc "start unicorn"
  task :unicorn do
    queue %{
      echo "-----> starting unicorn"
      #{echo_cmd %[cd #{deploy_to!}/#{current_path!} ; bundle exec unicorn -c config/unicorn.rb -D]}
    }
  end
end

namespace :install do

  desc "install bundler"
  task :bundler do
    queue %{
      echo "-----> install bundler"
      #{echo_cmd %[gem install bundler]}
    }
  end

end

namespace :db do

  desc "run migrations"
  task :migrate do
    queue %{
      echo "-----> migrating tables"
      #{echo_cmd %[cd #{deploy_to!}/#{current_path!} ; RAILS_ENV=production bundle exec rake db:migrate]}
    }
  end

  desc "seed the seed table"
  task :seed do
    queue %{
      echo "-----> Seeding/ updating seed tables"
      #{echo_cmd %[cd #{deploy_to!}/#{current_path!} ; RAILS_ENV=production bundle exec rake db:seed]}
    }
  end

end

