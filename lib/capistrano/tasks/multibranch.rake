namespace :multibranch do
  desc 'Create a new database from template'
  task :create_db do
    on roles(:db) do
      db_name = fetch(:db_name)
      if test(:psql, "-c '' #{db_name}")
        info "Database '#{db_name}' already exists!"
      else
        info "Creating database '#{db_name}'..."
        execute(:psql, "-c 'CREATE DATABASE \"#{db_name}\" TEMPLATE #{fetch(:db_template_name)}'")
      end
    end
  end

  desc 'Remove previously created db'
  task :remove_db do
    on roles(:db) do
      execute(:psql, "-c 'DROP DATABASE \"#{fetch(:db_name)}\"")
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
    execute("echo \"#{fetch(:db_name_env)}=#{fetch(:db_name)}\" >> #{fetch(:dotenv_file)}")
  end

  desc 'Removed deployed branch from server'
  task :cleanup do
    on roles(:app) do
      deploy_to = fetch(:deploy_to)
      execute("rm -rf #{deploy_to}") unless deploy_to == '/' # just to be sure ;)
    end
  end
  before :cleanup, :remove_db
end

namespace :load do
  task :defaults do
    if fetch(:multibranch_deployment)
      set :branch_normalized, -> { fetch(:branch).gsub(/[^A-Za-z0-9]/, '-') }
      set :db_name, -> { "#{fetch(:application)}_#{fetch(:branch_normalized)}" }
      set :deploy_to, -> { File.join(fetch(:deploy_to), fetch(:branch_normalized)) }
      set :base_domain, 'example.com'
      set :subdomain, -> { "#{fetch(:branch_normalized)}.#{fetch(:base_domain)}" }
      set :db_name_env, 'DB_NAME'
      set :dotenv_file, -> { ".env.#{fetch(:stage)}" }

      before  'deploy:updated',
              'multibranch:create_db',
              'multibranch:issue_certificate',
              'multibranch:set_env_vars'
    end
  end
end