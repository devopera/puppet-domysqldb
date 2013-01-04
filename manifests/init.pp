class domysqldb (

  # class arguments
  # ---------------
  # setup defaults

  $root_password = 'admLn**',
  $dbs = {},
  $dbs_default = {
    require => [Class['mysql'],Class['mysql::server']],
  },
  $user = 'root',
  $settings = {
    'mysqld' => {
#      'query_cache_limit'     => '5M',
#      'query_cache_size'      => '128M',
      'port'                  => 3306,
#      'skip-external-locking' => true,
#      'replicate-ignore-db'   => [
#        'tmp_table',
#        'whateveryouwant'
#      ]
    },
    'client' => {
      'port' => 3306
    },
  },

  # end of class arguments
  # ----------------------
  # begin class

) {

  # install REMI repository to get MySQL 5.5 on Centos 6
  case $operatingsystem {
    centos, redhat: {
      exec { 'common-mysqldb-five-five-repo' :
        path => '/usr/bin:/bin',
        command => 'rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm',
        user => 'root',
        creates => '/etc/yum.repos.d/remi.repo',
      }
      exec { 'common-mysqldb-five-five-install' :
        path => '/usr/bin:/bin',
        command => 'yum -y --enablerepo=remi,remi-test install mysql mysql-server',
        require => Exec['common-mysqldb-five-five-repo'],
      }
      file { 'common-mysqldb-five-five-common' :
        path => '/tmp/runonce-common-mysqldb-five-five-common.txt',
        require => Exec['common-mysqldb-five-five-install'],
      }
    }
    ubuntu, debian: {
      # MySQL 5.5 is default in 12.04
      file { 'common-mysqldb-five-five-common' :
        path => '/tmp/puppet-docommon-mysqldb-five-five-common.txt',
      }
    }
  }

  # install and setup mysql client and server
  class { 'mysql':
    require => File['common-mysqldb-five-five-common'],
  }
  class { 'mysql::server': 
    config_hash => { 'root_password' => $root_password },
    require => Class['mysql'],
  }

  # setup [non-out-of-the-box] config and restart mysqld
  mysql::server::config { 'domysqldb':
    settings => $settings,
    notify_service => true,
    require => Class['mysql::server'],
    creates => '/etc/mysql/conf.d/domysqldb.cnf',
  }

  # clean up insecure accounts and test database
  class { 'mysql::server::account_security':
    require => Class['mysql::server'],
  }

  # create databases
  create_resources(mysql::db, $dbs, $dbs_default)

}

# run a MySQL script once on a new system
define domysqldb::runonce (
  # @param command {string} name of script file to run
  $command = $title,
) {
  # run script as mysql root
  exec { "exec-${title}" :
    command => "/usr/bin/mysql -u root --password='${::domysqldb::root_password}' < $command; touch /tmp/puppet-domysqldb-runonce-${title}",
    creates => "/tmp/puppet-domysqldb-runonce-${title}",
  }
}

