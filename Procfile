sidekiq: bundle exec sidekiq --logfile $STACK_PATH/log/log/sidekiq.log --concurrency 5 --queue critical,8 --queue default,4 --queue low,2 --queue ultra_low,1
custom_web: bundle exec unicorn --config-file config/unicorn_cloud66.conf.rb --env $RAILS_ENV
