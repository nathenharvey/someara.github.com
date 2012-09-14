class chef-server {
# install FrameOS package repo
  exec { 'rbel6-release':
    command  => "/bin/rpm -Uvh http://rbel.co/rbel6",
    unless => "/bin/rpm -qa | grep rbel6-release"
  }

# list of packages to install
  $packages = [
    "couchdb",
    "rabbitmq-server",
    "rubygem-chef",
    "rubygem-chef-server",
    "rubygem-chef-solr",
    "rubygem-chef-expander",
    "rubygem-chef-server-api",
    "rubygem-chef-server-webui"
  ]

# install all the packages
  package { $packages:
    ensure => installed,
    require => Exec[ 'rbel6-release' ]
  }

# start couch
  service { 'couchdb':
    ensure => running,
    enable => true,
    hasstatus => true,
    require => Package[ $packages ],
  }

# start rabbitmq
  service { 'rabbitmq-server':
    ensure => running,
    enable => true,
    hasstatus => true,
    status => "service rabbitmq-server status | grep -e 'Pid .* running'",
    require => Package[ $packages ]
  }

# #FIXME - poke proper hole
# turn off iptables 
  service { 'iptables':
    ensure => stopped,
    enable => false,
    status => "/sbin/service iptables status | grep 'Table: filter'";
  }

# rabbitmq vhost
  exec { "add vhost chef to rabbitmq":
    command => "/usr/sbin/rabbitmqctl add_vhost /chef",
    unless => "/usr/sbin/rabbitmqctl list_vhosts | grep ^/chef",
    require => Service['rabbitmq-server']
  }

# rabbitmq user
  exec { "add user chef to rabbitmq":
    command => "/usr/sbin/rabbitmqctl add_user chef testing",
    unless => "/usr/sbin/rabbitmqctl list_users | grep chef",
    require => [
      Service['rabbitmq-server'],
      Exec['add vhost chef to rabbitmq']
    ]
  }

# rabbitmq permissions
  exec { "add chef permissions to rabbitmq":
    command => "/usr/sbin/rabbitmqctl set_permissions -p /chef chef \".*\" \".*\" \".*\"",
    unless => "/usr/sbin/rabbitmqctl list_permissions -p /chef | grep ^chef",
    require => [ 
      Service['rabbitmq-server'],
      Exec['add vhost chef to rabbitmq'],
      Exec['add user chef to rabbitmq']
    ]
  }

# log directory
  file { '/var/log/chef':
    ensure => directory,
    owner => "root",
    mode => "755",
    require => Package[ $packages ],
  }

# log files
  $cheflogfiles = [ '/var/log/chef/solr.log', '/var/log/chef/server.log', '/var/log/chef/server-webui.log' ]

  file { $cheflogfiles:
    ensure => present,
    owner => "root",
    mode => "644",
    require => [ 
      File[ '/var/log/chef' ],
      Package[ $packages ]
    ]
  }

# begin running services
  service { 'chef-server':
    ensure => running,
    enable => true,
    require => [ 
      Package[ $packages ],
      Exec[ 'add vhost chef to rabbitmq' ],
      Exec[ 'add user chef to rabbitmq' ],
      Exec[ 'add chef permissions to rabbitmq' ],
      File[ $cheflogfiles ]
    ]
  }

  service { 'chef-solr':
    ensure => running,
    enable => true,
    hasstatus => true,
    require => [
      Service['chef-server']
    ]
  }

  service { 'chef-expander':
    ensure => running,
    enable => true,
    hasstatus => true,
    require => [
      Service['chef-solr']
    ]
  }

  service { 'chef-server-webui':
    ensure => running,
    enable => true,
    require => [
      Service['chef-server'],
      Service[ 'iptables' ]
    ]
  }
}

