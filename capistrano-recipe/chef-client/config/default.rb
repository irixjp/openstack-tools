set :user, 'root'

CHEF_SERVER_URL="http://xxxxxxxxxxxxxxxxxx:4000"
VALID_PEM_GET_COMMAND="wget http://xxxxxxxxxxxxxx/pub/validation.pem -O /etc/chef/validation.pem; chmod 600 /etc/chef/validation.pem"

def unindent(s)
  return s.gsub(/^\s+/, '')
end

task :check_hostname do
   run 'hostname'
   run 'id'
end

load "./config/chef-client-install.rb"

