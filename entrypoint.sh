bundle exec rake db:migrate
bundle exec rake db:seed

unicorn -c config/unicorn.rb -D

service nginx start
