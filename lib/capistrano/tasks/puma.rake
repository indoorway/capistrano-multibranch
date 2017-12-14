namespace :multibranch do
  namespace :puma do

    task :stop do
      on roles(:app), in: :sequence, wait: 5 do
        within current_path do
          with rails_env: fetch(:rails_env) do
            if test("[ -f #{fetch(:puma_pid)} ]")
              execute(:bundle, "exec pumactl -P #{fetch(:puma_pid)} stop")
            end
          end
        end
      end
    end

    task :restart do
      on roles(:app), in: :sequence, wait: 5 do
        within current_path do
          with rails_env: fetch(:rails_env) do
            if test("[ -f #{fetch(:puma_pid)} ]")
              execute(:bundle, "exec pumactl -P #{fetch(:puma_pid)} restart")
            else
              execute(:bundle, "exec puma -dC #{fetch(:puma_config)}")
            end
            info "Successfully deployed branch '#{fetch(:branch)}' to '#{fetch(:subdomain)}'!"
          end
        end
      end
    end

  end
end

namespace :load do
  task :defaults do
    if fetch(:multibranch_deployment)
      set :puma_pid, -> { "#{shared_path}/tmp/pids/puma.pid" }
      set :puma_config, -> { "#{current_path}/config/puma.rb" }

      Rake::Task['deploy:restart'].clear_actions
      after 'deploy:finished', 'multibranch:puma:restart'
      before 'multibranch:remove_db', 'multibranch:puma:stop'
    end
  end
end
