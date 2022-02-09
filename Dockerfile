FROM ruby:3.0.0-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . .
ENV PORT=3000
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
# A java runtime is required to run the pin-press JAR file
# Git is required to install certain dependencies, however isn't needed after that.
RUN bundle config set --global deployment true \
    && bundle config set --global without development:test \
    && apk add --no-cache openjdk11-jre git make g++ postgresql-client postgresql-dev libpq tzdata \
    && bundle install \
    && apk del git g++ make

EXPOSE ${PORT}

CMD [ "./bin/rails", "server" ]