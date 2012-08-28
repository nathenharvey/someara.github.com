#
class chef-server {

  package { 'rbel6-release':
    source   => "http://rbel.co/rbel6",
  }

  package { 'couchdb':
    ensure => present,
    require => Package[ rbel6-release ],
  }

  package { 'rabbitmq-server':
    ensure => present,
    require => Package[ rbel6-release ],
  }

  package { 'rubygem-chef-server':
    ensure => present,
    require => Package[ 'rbel6-release' ],
    notify => Exec['/usr/sbin/setup-chef-server.sh']
  }

  exec { '/usr/sbin/setup-chef-server.sh':
    onlyif => "rabbitmqctl list_vhosts | grep ^/chef" 
  }

  service { 'couchdb':
    ensure => running,
    enable => true,
    require => Package[ 'couchdb' ],
  }

  service { 'rabbitmq-server':
    ensure => running,
    enable => true,
    require => Package[ 'rabbitmq-server' ],
  }

  service { 'chef-expander':
    ensure => running,
    enable => true,
    require => Package[ 'rubygem-chef-server' ],
  }

  service { 'chef-server':
    ensure => running,
    enable => true,
    require => Package[ 'rubygem-chef-server' ],
  }

  service { 'chef-solr':
    ensure => running,
    enable => true,
    require => Package[ 'rubygem-chef-server' ],
  }

  service { 'chef-server-webui':
    ensure => running,
    enable => true,
    require => Package[ 'rubygem-chef-server' ],
    require => Service[ 'chef-server' ],
  }

}
