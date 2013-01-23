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
  $innodb_buffer_pool_size = undef,
  $settings = {
    'mysqld' => {
      # redundant values already set in my.cnf
      #
      # 'user'                      => 'mysql',
      # 'port'                      => 3306,
      # 'default_storage_engine'    => 'innodb',
      # 'socket'                    => '/var/lib/mysql/data/mysql.sock',
      # 'pid_file'                  => '/var/run/mysqld/data/mysql.pid',
      # 'datadir'                   => '/var/lib/mysql/data/',
      # 'basedir'                   => '/usr',
      # 'tmpdir'                    => '/tmp',
      # 'skip-external-locking'     => true,
      # 'bind-address'              => '127.0.0.1',
      # 'log_error'                 => '/var/lib/mysql/data/mysql-error.log', (system dependent)
      # 'expire_logs_days'          => 14,
      #
      # can't be changed without wiping and re-creating log files
      # 'innodb_log_file_size'      => '64M',
      #
      'key_buffer_size'           => '32M',
      # INNODB
      'innodb'                    => 'FORCE',
      'innodb_log_files_in_group' => 2,
      'innodb_flush_log_at_trx_commit' => 1,
      'innodb_file_per_table'     => 1,
      # MyISAM
      'myisam_recover_options'    => 'FORCE,BACKUP',
      # Safety
      'skip_name_resolve'         => true,
      'sysdate_is_now'            => 1,
      # Caches and limits
      'max_allowed_packet'        => '16M',
      'max_connect_errors'        => 1000000,
      'max_connections'           => 256,
      'max_heap_table_size'       => '32M',
      'max_binlog_size'           => '100M',
      'query_cache_type'          => 1, # on by default
      'query_cache_size'          => '16M',
      'query_cache_limit'         => '1M',
      'thread_cache_size'         => 8,
      'table_definition_cache'    => 1024,
      'table_open_cache'          => 2048,
      'tmp_table_size'            => '32M',
      # Logging
      'log_bin'                   => '/var/lib/mysql/data/mysql-bin',
      'log_queries_not_using_indexes' => 0,
      'slow_query_log'            => 1,
      'slow_query_log_file'       => '/var/log/mysql/slow-query.log',
      'long_query_time'           => 5, # five seconds threshold by default
      'large_pages'               => true,
      'sync_binlog'               => 1,
    },
  },

  # end of class arguments
  # ----------------------
  # begin class

) {

  # derive variables and append to settings file using _additional var
  if $innodb_buffer_pool_size == undef {
    $memf_array = split($::memoryfree,' ')
    $innodb_buffer_pool_size_calc = inline_template('innodb_buffer_pool_size = <%= (memf_array[0].to_f * 1000 * 0.5).floor -%>M')
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
  }->
  # ensure all the necessary directories exist
  file { ['/var/log/mysql', '/var/lib/mysql', '/var/lib/mysql/data']:
    ensure => 'directory',
    owner => 'mysql',
    group => 'mysql',
  }->
  class { 'mysql::server': 
    config_hash => {
      # force error log to same place for CentOS and Ubuntu
      'log_error' => '/var/log/mysql/error.log',
      'root_password' => $root_password,
    },
  }

  # setup [non-out-of-the-box] config in /etc/mysql/conf.d/domysqldb.cnf and restart mysqld
  mysql::server::config { 'domysqldb':
    settings => $settings,
    settings_additional => "# Dynamically configured sizes\n${innodb_buffer_pool_size_calc}\n",
    notify_service => true,
    require => Class['mysql::server'],
  }->
  exec { 'scrub-old-mysqld-log-file':
    path => '/bin:/usr/bin',
    command => 'rm /var/log/mysqld.log',
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

