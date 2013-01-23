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
      'port'                      => 3306,
      'key_buffer_size'           => '32M',
      # INNODB
      'innodb'                    => 'FORCE',
      'innodb_log_files_in_group' => 2,
      'innodb_log_file_size'      => '64M',
      'innodb_flush_log_at_trx_commit' => 1,
      'innodb_file_per_table'     => 1,
      # MyISAM
      'myisam_recover_options'    => 'FORCE,BACKUP',
      # Safety
      'max_allowed_packet'        => '16M',
      'max_connect_errors'        => 1000000,
      'skip_name_resolve'         => true,
      'sysdate_is_now'            => 1,
      # Caches and limits
      'max_connections'           => 256,
      'max_heap_table_size'       => '32M',
      'query_cache_type'          => 0, # off by default
      'query_cache_size'          => 0,
      'thread_cache_size'         => 8,
      'table_definition_cache'    => 1024,
      'table_open_cache'          => 2048,
      'tmp_table_size'            => '32M',
      # Logging
      'log_slow_queries'          => '/var/log/mysql/slow-queries.log',
      'long_query_time'           => 5, # five seconds threshold by default
      'log_bin'                   => '/var/log/mysql/mysql-bin.log',
      'large_pages'               => true,
      'expire_logs_days'          => 14,
      'sync_binlog'               => 1,
    },
    'mysql' => {
      'port' => 3306
    },
  },

  # end of class arguments
  # ----------------------
  # begin class

) {

  # derive variables
  if defined $settings::mysqld::innodb_buffer_pool_size {
    $mem_float = $memoryfree
    $calc_value = $mem_float*1000/2
    $settings::mysqld::innodb_buffer_pool_size = "${calc_value}M"
  } else {
    # $settings->mysqld->innodb_buffer_pool_size = $innodb_buffer_pool_size
  }

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

  # setup [non-out-of-the-box] config in /etc/mysql/conf.d/domysqldb.cnf and restart mysqld
  mysql::server::config { 'domysqldb':
    settings => $settings,
    notify_service => true,
    require => Class['mysql::server'],
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

