
task :unset_selinux_iptables do
   run "chkconfig iptables off"
   run "/etc/init.d/iptables stop"
   run "chkconfig ip6tables off"
   run "/etc/init.d/ip6tables stop"
   run "setenforce 0"
   run "sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config"
end


task :set_epel_repository do
   put unindent(<<-CONF), "/etc/yum.repos.d/EPEL.repo"
      [EPEL]
      name=epel
      baseurl=http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/x86_64/
      enabled=1
      gpgcheck=1
      gpgkey=http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/RPM-GPG-KEY-EPEL-6
   CONF
end


#task :set_rbel_repogitory do
#   run <<-CMD
#      rpm -qa |grep rbel6-release;
#      export RETVAL=$?;
#      if [ $RETVAL != 0 ]; then
#         rpm -Uvh http://rbel.frameos.org/rbel6;
#      fi;
#   CMD
#   run "sed -i s/enabled\\ =\\ 1/enabled\\ =\\ 0/g /etc/yum.repos.d/rbel6.repo"
#end


task :install_dependency_package do
   run "yum install -y -q ruby rubygems ruby-devel ruby-rdoc ruby-ri ruby-shadow"
   run "yum install -y -q gcc gcc-c++ java make automake autoconf libxml2-devel gecode gecode-devel curl dmidecode zlib libxml"
end

task :install_goodies_package do
   run "yum install -y -q ntp vim-enhanced screen byobu expect nmap tcpdump tcptrace nc"
end

task :configure_ntp do
  transaction do
    put unindent(<<-'CONF'), '/etc/ntp.conf'
      restrict default kod nomodify notrap nopeer noquery
      restrict -6 default kod nomodify notrap nopeer noquery
      restrict 127.0.0.1 
      restrict -6 ::1
      server ntp.nict.jp
      server ntp.nict.jp
      server ntp.nict.jp
      server  127.127.1.0 # local clock
      fudge 127.127.1.0 stratum 10  
      driftfile /var/lib/ntp/drift
      keys /etc/ntp/keys
    CONF
    run 'chkconfig ntpd on'
    run 'service ntpd restart'
  end
end

task :install_couchdb do
  run 'service couchdb stop > /dev/null || true' # restart does not behave for some reason
  run 'yum -q -y install couchdb'
  run 'chkconfig couchdb on'
  # pity: we need nohup here, or else this hangs.
  run '(nohup service couchdb start > /dev/null ) && echo couchdb started',
      :pty => true, :shell => '/bin/bash'
end

task :install_rabbitmq do
  run 'yum -q -y install rabbitmq-server'
  run 'chkconfig rabbitmq-server on'
  run '(nohup service rabbitmq-server restart) && echo rabbitmq started',
      :pty => true, :shell => '/bin/bash'
end

after :install_rabbitmq do
  run <<-CMD
    ( rabbitmqctl list_vhosts | grep '/chef' ||  rabbitmqctl add_vhost /chef ) &&
    ( rabbitmqctl list_users | grep 'chef' || rabbitmqctl add_user chef testing ) &&
    rabbitmqctl set_permissions -p /chef chef ".*" ".*" ".*"
  CMD
end


task :install_chef_from_gem do
#   run "gem install libxml-ruby merb-assets merb-core merb-helpers merb-param-protection merb-slices thin merb-haml haml coderay  --no-rdoc --no-ri"
   run "gem install eventmachine -v 0.12.10 --no-rdoc --no-ri"
   run "gem install chef --no-rdoc --no-ri"
   run "gem install rack --no-rdoc --no-ri"
   run "gem install chef-server --no-rdoc --no-ri"
   run "gem install chef-server-api --no-rdoc --no-ri"
   run "gem install chef-solr --no-rdoc --no-ri"
   run "gem install chef-server-webui --no-rdoc --no-ri"
end

task :put_chef_config_files do
  run 'mkdir -p /etc/chef'
  Dir.glob("etc/chef/*") do |conffile|
    upload conffile, "/#{conffile}"
  end
end

task :put_init_scripts do
  path = '/etc/init.d/'
  Dir.glob ".#{path}/*" do |script|
    upload script, "/#{script}", :mode => 'u+x'
  end
end

task :setup_dirs_and_perms do
  chef_dirs = %w[cache log run lib].map { |d| "/var/#{d}/chef" }
  run 'id chef || adduser chef'
  run "mkdir -p #{chef_dirs.join ' '}"
  run "chown chef:chef #{chef_dirs.join ' '} -R"
end

task :enable_and_start_services do
  run "chef-solr-installer -u chef -g chef"
  services = %w[
    chef-solr
    chef-server
    chef-expander
    chef-server-webui
  ]
  services.each do |service|
    run <<-CMD
      chkconfig --add #{service} &&
      chkconfig #{service} on &&
      service #{service} start
    CMD
  end
end


task :setup_chef_server do
   unset_selinux_iptables
   set_epel_repository
#   set_rbel_repogitory
   install_dependency_package
   install_goodies_package
   configure_ntp
   install_couchdb
   install_rabbitmq
   install_chef_from_gem
   put_chef_config_files
   put_init_scripts
   setup_dirs_and_perms
   enable_and_start_services
end


