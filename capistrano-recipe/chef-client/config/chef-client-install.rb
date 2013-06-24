
task :install_dependency_package do
   run "yum install -y -q ruby rubygems ruby-devel"
   run "yum install -y -q gcc make wget"
end

task :install_chef_from_gem do
   run "gem install chef --no-rdoc --no-ri"
end

task :put_chef_config_files do
   run 'mkdir -p /etc/chef'
   put unindent(<<-CONF), "/etc/chef/client.rb"
      chef_server_url '#{CHEF_SERVER_URL}'
   CONF
end

task :get_validation_pem do
   run "#{VALID_PEM_GET_COMMAND}"
end

task :regist_chef_server do
   run "chef-client"
end

task :setup_chef_client do
   install_dependency_package
   install_chef_from_gem
   put_chef_config_files
   get_validation_pem
   regist_chef_server
end


