#!/bin/bash

rbenv global 2.1.2

while true
do
  echo "Fetching new metrics"
  bundle exec /nest/nest-to-carbon.rb;
  sleep 60;
done
