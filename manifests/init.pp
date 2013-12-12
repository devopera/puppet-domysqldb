class domysqldb (

  # class arguments
  # ---------------
  # setup defaults

  # type can be 'percona' or 'mariadb'
  $db_type = 'mysql',

  # version can be 55 or 56, though not all types are supported
  $db_version = '55',

  $root_password = 'admLn**',
  $dbs = {},
  $dbs_default = {
    require => [Class['mysql'],Class['mysql::server'],Class['mysql::server::account_security']],
  },
  $user = 'root',
  
  # subtle settings, rarely changed
  # timeout needs to be longer for really big databases
  $timeout_restart = 300,
  
  # static settings
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
      # 'expire_logs_days'          => 14,
      #
      'key_buffer_size'           => '32M',
      'log_error'                 => '/var/log/mysql/error.log',
      # INNODB
      'innodb'                    => 'FORCE',
      'innodb_log_files_in_group' => 2,
      'innodb_log_file_size'      => '64M',
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

  # install packages
  # - client
  if ! defined(Class['domysqldb::repoclient']) {
    # install MySQL client
    class { 'domysqldb::repoclient': 
      db_type => $db_type,
      db_version => $db_version,
    }
  }

  # - server
  case $db_type {
    mysql: {
      # install MySQL server 5.5
      case $operatingsystem {
        centos, redhat, fedora: {
          exec { 'common-mysqldb-five-five-install' :
            path => '/usr/bin:/bin',
            command => 'yum -y --enablerepo=remi,remi-test install mysql-server mysql-devel',
            require => Class['domysqldb::repoclient'],
            before => Class['mysql'],
          }
        }
        ubuntu, debian: {
          # MySQL 5.5 is default in 12.04
          # but can't install with package because of mysql module conflict
          # package { 'mysql-server' :
          #   ensure => 'present',
          # }->
          exec { 'common-mysqldb-five-five-install' :
            path => '/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
            command => 'apt-get -y -q -o DPkg::Options::=--force-confold install mysql-server',
            require => Class['domysqldb::repoclient'],
            before => Class['mysql'],
          }->
          # install other packages (required for python pip installs)
          package { 'libmysqlclient-dev' :
            ensure => present,
          }
        }
      }
    }
  }


  # setup dynamic variables
  
  # generate dynamic buffer_pool_size if not set
  if ($settings['mysqld']['innodb_buffer_pool_size'] == undef) {
    $memf_array = split($::memorytotal,' ')
    if ($::memorytotal =~ /GB/) {
      $memf = inline_template('<%= (memf_array[0].to_f * 1000 * 0.35).floor -%>')
    } else {
      $memf = inline_template('<%= (memf_array[0].to_f * 0.35).floor -%>')
    }
    $innodb_buffer_pool_size_calc = "innodb_buffer_pool_size = ${memf}M"
  } else {
    # no additional dynamic setting to include, just the defined one
    $innodb_buffer_pool_size_calc = ''
  }

  if ($settings['mysqld']['innodb_log_file_size'] == undef) {
    # log file is 5MB by default
    $innodb_log_file_size_bytes = 5242880
  } else {
    # derive size from setting
    $size_mb = $settings['mysqld']['innodb_log_file_size']
    $innodb_log_file_size_bytes = inline_template('<%= (size_mb.to_f * 1024 * 1024).floor -%>')
  }
  # notify { "debugging: ${innodb_log_file_size_bytes} bytes" : }


  # configure mysql client and server
  class { 'mysql': }->
  # ensure all the necessary directories exist (as directories or symlinks)
  docommon::createdir { ['/var/log/mysql', '/var/lib/mysql', '/var/lib/mysql/data']:
    owner => 'mysql',
    group => 'mysql',
  }->
  # selected my.cnf settings are overriden later by /etc/mysql/conf.d/ files
  class { 'mysql::server': 
    config_hash => {
      'root_password' => $root_password,
    },
  }

  $settings_via_template = template('mysql/my.conf.cnf.erb') 
  # shutdown mysql, but only after mysql::config has completely finished
  exec { 'domysqldb-shutdown':
    path => '/sbin:/usr/bin',
    command => "service ${mysql::params::service_name} stop",
    tag => ['service-sensitive'],
    require => [Class['mysql::server'], Class['mysql::config'], Exec['mysqld-restart']],  
  }

  # if the log files have been moved, create new log files as mysql user
  if ($settings['mysqld']['log_error'] != undef) {
    exec { 'domysqldb-create-new-log-error':
      path => '/bin:/usr/bin',
      command => "touch ${settings['mysqld']['log_error']}",
      user => 'mysql',
      group => 'mysql',
      before => Exec['domysqldb-startup'],
      require => Exec['domysqldb-shutdown'],
    }
  }
  if ($settings['mysqld']['slow_query_log_file'] != undef) {
    exec { 'domysqldb-create-new-log-slow':
      path => '/bin:/usr/bin',
      command => "touch ${settings['mysqld']['slow_query_log_file']}",
      user => 'mysql',
      group => 'mysql',
      before => Exec['domysqldb-startup'],
      require => Exec['domysqldb-shutdown'],
    }
  }
  # delete old binary log files and deps if wrong size
  if ($innodb_log_file_size_bytes != undef) {
    $tmptarget = '/tmp/puppet-domysqldb-old-ibdatas'
    # ensure that a dump directory exists in /tmp
    file { "$tmptarget" :
      ensure => 'directory',
      mode => 0777,
    }->
    exec { 'domysqldb-scrub-old-binlog-wrong-size' :
      path => '/bin:/usr/bin',
      command => "mv /var/lib/mysql/ib_logfile* $tmptarget && mv /var/lib/mysql/ibdata* $tmptarget",
      onlyif => "test `stat -c \'%s\' /var/lib/mysql/ib_logfile0` -ne ${innodb_log_file_size_bytes}",
      before => Exec['domysqldb-startup'],
      require => Exec['domysqldb-shutdown'],
    }
  }
  # setup [non-out-of-the-box] config after my.cnf has been setup by mysql::server
  file { '/etc/mysql/conf.d/domysqldb.cnf':
    ensure  => file,
    content => "${settings_via_template}\n# Dynamically configured sizes\n${innodb_buffer_pool_size_calc}\n\n",
    owner   => 'root',
    group   => $mysql::params::root_group,
    mode    => '0644',
    before => Exec['domysqldb-startup'],
    require => Exec['domysqldb-shutdown'],
  }

  # start [from stopped] mysql to create new log files (if necessary) and read new conf.d config
  exec { 'domysqldb-startup' :
    path => '/sbin:/usr/bin',
    command => "service ${mysql::params::service_name} start",
    tag => ['service-sensitive'],
    timeout => $timeout_restart,
    require => Exec['domysqldb-shutdown'],
  }->
  # clean up insecure accounts and test database
  class { 'mysql::server::account_security':
    require => Class['mysql::server'],
  }->
  # add back a user entry for root@127.0.0.1
  # can't use database_user resource (conflicts with mysql::server::account_security)
  #database_user { "root@127.0.0.1":
  #  ensure        => present,
  #  password_hash => mysql_password($root_password),
  #  provider      => 'mysql',
  #}-> 
  #database_grant { "root@127.0.0.1/*":
  #  privileges => ['all'],
  #  provider   => 'mysql',
  #}
  exec { 'domysqldb-enable-root-localhost-ip' :
    path => '/bin:/usr/bin',
    command => "mysql -u root --password='${root_password}' -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1'  IDENTIFIED BY '${root_password}';\"",
  }
  
  # delete old log file if it is now redundant
  if (($settings['mysqld']['log_error'] != undef) and ($settings['mysqld']['log_error'] != '/var/log/mysqld.log')) {
    exec { 'domysqldb-scrub-old-mysqld-log-file':
      path => '/bin:/usr/bin',
      command => 'rm /var/log/mysqld.log',
      onlyif => 'test -f /var/log/mysqld.log',
      require => Exec['domysqldb-startup'],
    }
  }

  # create databases
  create_resources(mysql::db, $dbs, $dbs_default)

}

