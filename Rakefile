#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

Rake::Task[:build].enhance [:compile]

desc 'Compile oojspec static files'
task :compile do
  system 'rm -rf dist && npm install && node_modules/.bin/webpack' or
    abort('could not compile oojspec')
end
