FROM ruby:2.5.1-alpine3.7

LABEL MAINTAINER "Ahmad Amireh <ahmad@instructure.com>"

RUN apk add --no-cache build-base git

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN bundle install \
      --frozen \
      --without development \
      --deployment && \
    apk del --no-cache build-base git

ENTRYPOINT [ "bundle", "exec", "kong_schema" ]
