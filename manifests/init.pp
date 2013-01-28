class domysqldb (

  # class arguments
  # ---------------
  # setup defaults

  $root_password = 'admLn**',
  $dbs = {},
  $dbs_default = {
    require => [Class['mysql::server::account_security']],
  },

  # my.cnf settings
  $user = 'mysql',
  $config_file       = $mysql::params::config_file,
  $socket            = $mysql::params::socket,        # '/var/lib/mysql/data/mysql.sock'
  $port              = $mysql::params::port,          # 3306
  $service_name      = $mysql::params::service_name,  # mysqld
  $bind_address      = $mysql::params::bind_address,  # '127.0.0.1'
  $pidfile           = $mysql::params::pidfile,       # '/var/run/mysqld/data/mysql.pid'
  $basedir           = $mysql::params::basedir,       # '/usr'
  $datadir           = $mysql::params::datadir,       # '/var/lib/mysql/data/'
  $ssl               = $mysql::params::ssl,           # false
  $ssl_ca            = $mysql::params::ssl_ca,        # '/etc/mysql/cacert.pem'
  $ssl_cert          = $mysql::params::ssl_cert,      # '/etc/mysql/server-cert.pem'
  $ssl_key           = $mysql::params::ssl_key,       # '/etc/mysql/server-key.pem'
  $log_error         = '/var/log/mysql/error.log',    # force Centos/Ubuntu parity

  # dynamic settings (if undefined)
  $innodb_buffer_pool_size = undef,

  # other settings
  $settings = {
    'mysqld' => {
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
    $memf_array = split($::memorytotal,' ')
    $innodb_buffer_pool_size_calc = inline_template('innodb_buffer_pool_size = <%= (memf_array[0].to_f * 1000 * 0.35).floor -%>M')
  } else {
    $innodb_buffer_pool_size_calc = "innodb_buffer_pool_size = ${innodb_buffer_pool_size}"
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

  # initialise variables
  $settings_via_template = template('mysql/my.conf.cnf.erb') 

  # install mysql client
  class { 'mysql':
    require => File['common-mysqldb-five-five-common'],
  }->
  package { 'mysql-server':
    ensure => 'present',
    name   => $mysql::params::server_package_name,
  }->
  
  # ensure all the necessary directories exist
  file { ['/var/log/mysql', '/var/lib/mysql', '/var/lib/mysql/data', '/etc/mysql', '/etc/mysql/conf.d']:
    ensure => 'directory',
    owner => 'mysql',
    group => 'mysql',
    mode => 0755,
  }->
  # delete old binary log file if wrong size (!=64M)
  exec { 'domysqldb-scrub-old-binlog-wrong-size' :
    path => '/bin:/usr/bin',
    command => "rm -rf /var/lib/mysql/ib_logfile*",
    onlyif => 'test `stat -c \'%s\' /var/lib/mysql/ib_logfile0` -ne 67108864', 
  }->
  # delete old log file if in wrong place
  exec { 'domysqldb-scrub-old-mysqld-log-file':
    path => '/bin:/usr/bin',
    command => 'rm /var/log/mysqld.log',
    onlyif => 'test -f /var/log/mysqld.log',
  }->
  # create new log file as mysql user
  exec { 'domysqldb-create-new-log-file':
    path => '/bin:/usr/bin',
    command => "touch $log_error",
    user => 'mysql',
    group => 'mysql',
  }->
  
  # setup generic my.cnf
  file { '/etc/my.cnf':
    content => template('domysqldb/my.cnf.erb'),
    owner  => 'root',
    group  => $mysql::params::root_group,
    mode    => '0644',
  }->
  # setup [non-out-of-the-box] config
  file { "/etc/mysql/conf.d/domysqldb.cnf":
    ensure  => file,
    content => "${settings_via_template}\n# Dynamically configured sizes\n${innodb_buffer_pool_size_calc}\n",
    owner   => 'root',
    group   => $mysql::params::root_group,
    mode    => '0644',
  }->
  # set root password for root-auto-access
  file { '/root/.my.cnf':
    content => template('mysql/my.cnf.pass.erb'),
    owner  => 'root',
    group  => $mysql::params::root_group,
    mode   => '0400',
  }->
  
  # start the service for the first time
  service { 'mysqld':
    ensure   => 'running',
    name     => $service_name,
    enable   => true,
    require  => Package['mysql-server'],
    provider => $mysql::params::service_provider,
  }->
  
  # set the root password if not same
  exec { 'set_mysql_rootpw':
    command   => "mysqladmin -u root '' password '${root_password}'",
    logoutput => true,
    unless    => "mysqladmin -u root -p'${root_password}' status > /dev/null",
    path      => '/usr/local/sbin:/usr/bin:/usr/local/bin',
    require   => File['/etc/mysql/conf.d'],
  }->

  # clean up insecure accounts and test database
  class { 'mysql::server::account_security': }

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
    command => "/usr/bin/mysql -u root --password='${::domysqldb::root_password}' < $command && touch /tmp/puppet-domysqldb-runonce-${title}",
    creates => "/tmp/puppet-domysqldb-runonce-${title}",
  }
}

