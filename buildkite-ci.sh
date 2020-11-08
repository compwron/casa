#!/bin/bash
set -eu

# https://buildkite.com/docs/pipelines/example-pipelines

curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter
chmod +x ./cc-test-reporter
./cc-test-reporter before-build
psql -c 'create database casa_test;' -U postgres
psql -c 'create database casa_development;' -U postgres
ln -s /usr/lib/chromium-browser/chromedriver ~/bin/chromedriver
nvm use stable

gem install bundler
nvm install node --reinstall-packages-from=node
npm install --global yarn
bundle install
yarn
bundle install

bundle exec rails webpacker:compile
bundle exec brakeman
bundle exec standardrb
RUBYOPT='-W:no-deprecated -W:no-experimental' bundle exec rspec
RAILS_ENV=test bundle exec rails server -b 0.0.0.0 -p 4040 -d
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake db:seed
npm run test:cypress
kill $(jobs -p) || true

./cc-test-reporter after-build --exit-code $TRAVIS_TEST_RESULT
