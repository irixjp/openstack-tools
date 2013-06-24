set :user, 'root'

task :check_hostname do
   run 'hostname'
   run 'id'
end

load "./config/chef-install.rb"

