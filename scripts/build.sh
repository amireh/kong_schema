#!/usr/bin/env bash

version="$(bundle exec ruby -r ./lib/kong_schema/version -e 'STDOUT.write KongSchema::VERSION')"

gem build kong_schema.gemspec &&
docker build . -t amireh/kong-schema:"$version"