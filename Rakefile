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
  system 'npm install' or abort('could not compile oojspec')
end
