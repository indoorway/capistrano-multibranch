# Capistrano::Multibranch

Capistrano plugin for deploying separate application per feature branch. It creates a separate PostgreSQL database from the given template, issues a new SSL certificate using Let's encrypt and sets additional env varaibles for each branch deployment.

## Installation

Add this line to your application's Gemfile:

```
gem 'capistrano-multibranch', github: 'indoorway/capistrano-multibranch', group: :development
```

## Usage

You probably want to run this tasks only on `staging` environment so add these lines to your `Capfile`:

```
task :use_multibranch_deployment do
  require 'capistrano/multibranch'
end

task staging: [:use_multibranch_deployment]
```

To deploy a branch `foo-bar` to your staging server use:

```
BRANCH_NAME=foo-bar cap staging deploy
```

Following tasks will be run automatically during deployment:

```
# before 'deploy:migrate'
      - multibranch:set_env_vars
      - multibranch:create_db
      - multibranch:issue_certificate
# after 'deploy:finished'
      - deploy:restart
```

## Configuration

```
set :db_name, 'foo_db'                # Default: "#{application}_#{branch}"
set :db_template_name, 'foo_tempalte' # Default: "#{application}_template"
set :db_name_env, 'FOO_DB_NAME'       # Default: DB_NAME
set :base_domain, 'foo-bar.com'       # Base staging domain of your app. Default: example.com
set :dotenv, { api_url: 'baz.com' }   # Additional env vars to be added to dotenv file. Default: {}
set :dotenv_file, '~/.env'            # Defalt: "#{release_path}/.env.#{stage}.local"
```
