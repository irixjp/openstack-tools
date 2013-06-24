#!/bin/bash

yum install -y ruby rubygems ruby-devel ruby-rdoc ruby-ri gcc make
gem install capistrano        --no-rdoc --no-ri
gem install capistrano_colors --no-rdoc --no-ri
gem install capistrano-ext    --no-rdoc --no-ri

