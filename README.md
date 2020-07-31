# Reindeer Hunt Console

## Setup

### Prerequisites

-   Correct Ruby and Rails installed
-   Yarn package manager

### Fast setup

```bash
bundle
yarn
```

Create a .env file and set the following environment variables:

```
export RACK_ENV=development
export PORT=3000
export JDBC_DATABSE_URL=<databse url for local machine's development database>
```

This file should be loaded on launch by [dotenv-rails](https://github.com/bkeepers/dotenv)

Create `config/master.key` and place the original private key that was generated upon the app's creation.

#### Debugging

In order to be able to use launch configurations to debug, the recommended extensions should be installed, and the `ruby-debug-ide` extension will also be needed:

```bash
gem install ruby-debug-ide rufo rubocop solargraph
```

## Heroku Setup

This application is currently set up to run on Heroku for its production environment.

The following setup is needed:

-   Installed [Redis To Go](https://elements.heroku.com/addons/redistogo) add-on.
    -   Configured `REDIS_URL` config var to the `REDISTOGO_URL` var
-   Installed Heroku Postgres add-on (should be installed by default).
-   Added the [Heroku java buildpack](https://help.heroku.com/2FSHO0RR/how-can-i-add-java-to-a-non-java-app).

Environment variables that need setting:
RACK_ENV (set by heroku)
PORT: Set to the port to use when launching the server. Only needed if you're running the server with the heroku CLI locally, and even then defaults to 3000. See [Procfile](./Procfile)
REDISTOGO_URL (redis server URL used in production for action cable)
SECRET_KEY_BASE (not sure if this is needed or not, if it is created automatically or what)
JDBC_DATABASE_URL: Needs to be the URL at which the database is accessible. Format: `postgres://<username>:<password>@<domain>:<port>/<database_name>`.
RAILS_MASTER_KEY=<private key for credentials.yml.enc>
