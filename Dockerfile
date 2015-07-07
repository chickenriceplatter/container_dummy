FROM ruby:latest
RUN apt-get update -qq && apt-get install -y build-essential nodejs libpq-dev nginx

RUN mkdir /myapp

WORKDIR /tmp
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install

RUN mkdir -p /logs/nginx

RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
RUN mkdir -p /etc/nginx/sites-enabled
COPY nginx.conf /etc/nginx/nginx.conf
COPY default /etc/nginx/sites-enabled/default

RUN mkdir -p "/var/run/deploy"

ADD . /myapp
WORKDIR /myapp

ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=8085bd8a2e9f4eb9ca3d8f5dc424608b1d7aba9c08a910c8ccd832b7536ae712650ebb6d88966e4feb2d01c38aa7bae166a978c224134d18507a8acf85715646
ENV RAILS_SERVE_STATIC_FILES=1

RUN echo $(pwd)

RUN bundle exec rake assets:precompile --trace

ADD entrypoint.sh /myapp/entrypoint.sh

ENTRYPOINT /myapp/entrypoint.sh
