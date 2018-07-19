#!/usr/bin/env bash

version="$(bundle exec ruby -r ./lib/kong_schema/version -e 'STDOUT.write KongSchema::VERSION')"

echo "publishing to rubygems" &&
gem push kong_schema-"$version".gem &&
echo "publishing to docker" &&
docker push amireh/kong-schema:"$version"