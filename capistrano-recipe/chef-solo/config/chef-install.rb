def unindent(s)
  return s.gsub(/^\s+/, '')
end

desc "Install ruby from yum"
task :install_ruby_packages do
   run <<-CMD
     yum install -y -q ruby rubygems ruby-devel \
        gcc make git
   CMD
end

desc "Check command ruby & gem"
task :check_ruby_and_gem do
   run 'ruby -v'
   run 'gem -v'
end


desc "Install chef from gem"
task :install_chef_solo do
   run 'gem install chef --no-rdoc --no-ri'
   run 'gem install knife-solo --no-rdoc --no-ri'
end


desc "Check command chef-solo"
task :check_chef_solo do
   run 'chef-solo -v'
end


desc "Put chef config files"
task :put_chef_config_files do
   run "mkdir -p ~/.chef"

   put unindent(<<-CONF), ".chef/knife.rb"
      current_dir = File.dirname(__FILE__)
      user = ENV['OPSCODE_USER'] || ENV['USER']
      node_name                ""
      client_key               ""
      validation_client_name   ""
      validation_key           "\#{ENV['HOME']}/.chef/\#{ENV['ORGNAME']}-validator.pem"
      chef_server_url          ""
      cache_type               'BasicFile'
      cache_options( :path => "\#{ENV['HOME']}/.chef/checksums" )
      cookbook_path            "/etc/chef/cookbooks"
      cookbook_copyright       "Your Company, Inc."
      cookbook_license         "apachev2"
      cookbook_email           "cookbooks@yourcompany.com"
   CONF

   run <<-CMD
     cd;
     perl -pi -e "s/^node_name.*/node_name                \\"$CAPISTRANO:HOST$\\"/" .chef/knife.rb
   CMD

   run <<-CMD
     if `test -d /etc/chef`; then
       rm -Rf /etc/chef;
     fi
   CMD

   run 'knife kitchen /etc/chef'

   put unindent(<<-CONF), "/etc/chef/solo.rb"
     file_cache_path "/var/chef-solo"
     cookbook_path   "/etc/chef/cookbooks"
     json_attribs    "/root/node.json"
     node_name       ""
     log_location    "/var/log/chef/solo.log"
     log_debug       :debug
   CONF

   run <<-CMD
     cd;
     perl -pi -e "s/^node_name.*/node_name       \\"$CAPISTRANO:HOST$\\"/" /etc/chef/solo.rb
   CMD

   run 'mkdir -p /var/log/chef'
   run 'mkdir -p /var/chef-solo'
end


desc "Execute all subtask for chef-solo"
task :chef_solo_setup_with_default_configs do
  install_ruby_packages
  check_ruby_and_gem
  install_chef_solo
  check_chef_solo
  put_chef_config_files
end

