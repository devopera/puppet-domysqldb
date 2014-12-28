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
    require => [Class['mysql::client'], Class['mysql::server'], Class['mysql::server::account_security']],
  },
  $user = 'root',
  $real_root_home = '/root',
  
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
      # MyISAM (throws error in Ubuntu 14.04)
      # 'myisam_recover_options'    => 'FORCE,BACKUP',
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
    'mysqld_safe' => {
      'log_error'                 => '/var/log/mysql/error.log',
    }
  },

  # end of class arguments
  # ----------------------
  # begin class

) {

  # setup dynamic variables
  # generate dynamic buffer_pool_size if not set
  if ($settings['mysqld']['innodb_buffer_pool_size'] == undef) {
    $memf_array = split($::memorysize_mb,' ')
    $memf = inline_template('<%= (memf_array[0].to_f * 0.35).floor -%>')
    # catch bad value
    if ($memf == 0) {
      fail('domysqldb error: unable to read memory size of machine')
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
        centos, redhat: {
          exec { 'common-mysqldb-five-five-install' :
            path => '/usr/bin:/bin',
            command => 'yum -y --enablerepo=remi,remi-test install mysql-server mysql-devel',
            require => Class['domysqldb::repoclient'],
            before => Class['mysql::client'],
          }
          $package_name = undef
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
            before => Class['mysql::client'],
          }->
          # install other packages (required for python pip installs)
          package { 'libmysqlclient-dev' :
            ensure => present,
          }
          $package_name = undef
        }
        
        fedora: {
          $package_name = 'mariadb-server'
          exec { 'domysqldb-mysql-create-user-group-manually' :
            path => '/bin:/usr/bin:/sbin:/usr/sbin',
            command => 'groupadd mysql && useradd -r -g mysql mysql',
            before => [Anchor['domysqldb-pre-server-install']],
            # only add user if not already there
            onlyif => 'test `/bin/egrep  -i "^mysql" /etc/passwd | wc -l` == 0',
          }
        }
      }
    }
  }

  # output debugging information
  notify { "debugpoint: domysqldb reads root_home as '${::root_home}'" : }

  # configure mysql server
  anchor { 'domysqldb-pre-server-install' : }
  
  # ensure all the necessary directories exist (as directories or symlinks)
  docommon::createdir { ['/var/log/mysql', '/var/lib/mysql', '/var/lib/mysql/data']:
    owner => 'mysql',
    group => 'mysql',
    # need to wait for mysql class (client install) to create mysql user/group, but that creates dep cycle
    # require => [Class['mysql::client'], Anchor['domysqldb-pre-server-install']],
    require => [Anchor['domysql-user']],
  }

  # create a user only if it doesn't exist already
  anchor { 'domysql-user': }

  exec { 'domysql-mysql-create-user' :
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => 'id -u mysql &>/dev/null || useradd -u 27 -d /var/lib/mysql mysql',
    before => [Anchor['domysql-user']],
  }
  # can't use mysql type because Ubuntu chokes on overwriting
  # if ! defined(User['mysql']) {
  #   user { 'mysql-user': 
  #     name => 'mysql',
  #     shell => '/bin/bash',
  #     uid => 27,
  #     ensure => 'present',
  #     managehome => true,
  #     home => '/var/lib/mysql',
  #     comment => 'MySQL server user',
  #   }
  # }
  
  # selected my.cnf settings are overriden later by /etc/mysql/conf.d/ or /etc/my.cnf.d/ files
  class { 'mysql::server': 
    package_name => $package_name,
    # don't set the root password because it conflicts with pre-set root passwords and wipes root@localhost grants
    root_password => 'UNSET',
    # don't remove default accounts because it conflicts as above (also wipes out root@127.0.0.1 which we need for tunnelled connections)
    # remove_default_accounts => true,
    # set override settings at server install (/etc/my.cnf) to avoid fixes later
    override_options => $settings,
    before => Anchor['domysqldb-mysql-up-for-internal'],
  }

  # cover the case where MySQL was started before /etc/my.cnf was created
  if ($innodb_log_file_size_bytes != undef) {
    class { 'domysqldb::fixibdata' :
      new_size => $innodb_log_file_size_bytes,
      before => [Anchor['domysqldb-mysql-up-for-internal']],
    }

    # setup order
    Class['mysql::server::config'] ->
    Class['domysqldb::fixibdata'] ->
    Class['mysql::server::service']
  }
  
  anchor { 'domysqldb-mysql-up-for-internal' : }

  # create root@localhost user/password using mysqladmin because mysql_user/mysql_grant locks itself out
  exec { 'domysqldb-setup-root-user' :
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "mysqladmin -u root password '${root_password}'; mysql -u root --password='${root_password}' -NBe \"GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY '${root_password}' WITH GRANT OPTION\"",
    require => [Class['mysql::server'], Anchor['domysqldb-mysql-up-for-internal']],
  }->
  
  # create .my.cnf in correct location only, not erroneous puppetlabs-mysql $::root_home
  file { ["${real_root_home}/.my.cnf"]:
    content => template('domysqldb/my.cnf.pass.erb'),
    owner   => 'root',
    mode    => '0600',
  }->
  
  # delete any redundant log files
  class { 'domysqldb::cleanlogs' :
    settings => $settings,
  }->
  
  anchor { 'domysqldb-mysql-up' : }

  mysql_user { 'root@127.0.0.1' :
    password_hash            => mysql_password($root_password),
    ensure                   => present,
    max_connections_per_hour => '0',
    max_queries_per_hour     => '0',
    max_updates_per_hour     => '0',
    max_user_connections     => '0',
    require                  => [Anchor['domysqldb-mysql-up']],
  }->
  mysql_grant { 'root@127.0.0.1/*.*' :
    ensure     => present,
    user       => 'root@127.0.0.1',
    options    => ['GRANT'],
    privileges => [ 'ALL' ],
    table      => '*.*',
    before => Anchor['domysqldb-finished'],
  }

  # manually remove insecure accounts
  mysql_user {
    [ "root@${::fqdn}",
      # don't remove root@127.0.0.1
      # 'root@127.0.0.1',
      'root@::1',
      "@${::fqdn}",
      '@localhost',
      '@%']:
    ensure  => 'absent',
    require => Anchor['domysqldb-mysql-up'],
    before => Anchor['domysqldb-finished'],
  }

  # can't use puppetlabs-mysql template due to .sort() function error
  # $settings_via_template = template('mysql/my.cnf.erb') 
  $settings_via_template = template('domysqldb/my.cnf.erb') 

  # setup additional dynamic config after my.cnf has been setup by mysql::server
  file { "${mysql::params::includedir}/domysqldb.cnf":
    ensure  => file,
    content => "[mysqld]\n# Dynamically configured sizes\n${innodb_buffer_pool_size_calc}\n\n",
    owner   => 'root',
    group   => $mysql::params::root_group,
    mode    => '0644',
    notify  => [Service['mysqld']],
  }

  # create databases
  create_resources(mysql::db, $dbs, $dbs_default)

  # make sure we've really finished atomically
  anchor { 'domysqldb-finished' : }
}

