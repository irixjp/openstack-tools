set :user, 'root'

def unindent(s)
  return s.gsub(/^\s+/, '')
end

task :check_hostname do
   run 'hostname'
   run 'id'
end

load "./config/chef-server-install.rb"

