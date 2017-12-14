namespace :multibranch do
  desc 'Setup deploy_to for multideployment'
  task :set_deploy_to do
    set :deploy_to, File.join(fetch(:deploy_to), fetch(:branch_normalized))
  end

  desc 'Create a new database from template'
  task :create_db do
    on roles(:db) do
      db_name = fetch(:db_name)
      if test(:psql, "-c '' #{db_name}")
        info "Database '#{db_name}' already exists!"
      else
        info "Creating database '#{db_name}'..."
        execute(:psql, "-d #{fetch(:db_template_name)} -c 'CREATE DATABASE \"#{db_name}\" TEMPLATE #{fetch(:db_template_name)}'")
      end
    end
  end

  desc 'Remove previously created db'
  task :remove_db do
    on roles(:db) do
      db_name = fetch(:db_name)
      if test(:psql, "-c '' #{db_name}")
        execute(:psql, "-d #{fetch(:db_template_name)} -c 'DROP DATABASE \"#{fetch(:db_name)}\"'")
      end
    end
  end

  desc 'Issue a new SSL certificate for subdomain'
  task :issue_certificate do
    on roles(:app) do
      subdomain = fetch(:subdomain)
      openssl_list = capture("sudo openssl x509 -noout -text -in /etc/letsencrypt/live/master.#{fetch(:base_domain)}/cert.pem | grep DNS")
      current_subdomains = openssl_list.strip.split(', ').map{ |s| s[4..-1] }
      if current_subdomains.include? subdomain
        info "Certificate already covers the subdomain '#{subdomain}'!"
      else
        info "Extending the current certficate with sudomain '#{subdomain}'..."
        args = [*current_subdomains, subdomain].map{ |d| "-d #{d}" }.join(' ')
        execute('sudo systemctl stop nginx')
        execute("sudo certbot certonly -a standalone --expand #{args}")
        execute('sudo systemctl start nginx')
      end
    end
  end

  desc 'Add database name env variable to dotenv file'
  task :set_env_vars do
    on roles(:app) do
      within release_path do
        dotenv = { fetch(:db_name_env) => fetch(:db_name) }.merge(fetch(:dotenv))
        envs = dotenv.map { |k, v| "#{k.upcase}=#{v}" }.join('\n')
        execute("echo \"#{envs}\" >> #{fetch(:dotenv_file)}")
      end
    end
  end

  desc 'Removed deployed branch from server'
  task :cleanup do
    on roles(:app) do
      deploy_to = fetch(:deploy_to)
      execute("rm -rf #{deploy_to}") unless deploy_to == '/' # just to be sure ;)
    end
  end
end

namespace :deploy do
  task :restart do
    on roles(:app), in: :groups, limit: 3, wait: 10 do
      within release_path do
        execute :touch, 'tmp/restart.txt'
        info "Successfully deployed branch '#{fetch(:branch)}' to 'https://#{fetch(:subdomain)}'!"
      end
    end
  end
end

namespace :load do
  task :defaults do
    set :branch, ENV['REVISION'] || ENV['BRANCH_NAME'] || 'master'
    set :branch_normalized, -> { fetch(:branch).gsub(/[^A-Za-z0-9]/, '-') }
    set :db_name, -> { "#{fetch(:application)}_#{fetch(:branch_normalized)}" }
    set :db_template_name, -> { "#{fetch(:application)}_template" }
    set :db_name_env, 'DB_NAME'
    set :base_domain, 'example.com'
    set :subdomain, -> { "#{fetch(:branch_normalized)}.#{fetch(:base_domain)}" }
    set :dotenv, {}
    set :dotenv_file, -> { File.join(release_path, ".env.#{fetch(:stage)}.local") }
  end
end

before  'deploy:starting', 'multibranch:set_deploy_to'
before  'deploy:migrate', 'multibranch:create_db'
before  'multibranch:create_db', 'multibranch:set_env_vars'
before  'deploy:finished', 'multibranch:issue_certificate'
after   'deploy:finished', 'deploy:restart'

before 'multibranch:remove_db', 'multibranch:set_deploy_to'
before 'multibranch:cleanup', 'multibranch:remove_db'
