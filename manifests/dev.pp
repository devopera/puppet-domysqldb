class domysqldb::dev (

  # class arguments
  # ---------------
  # setup defaults

  $db_port = 3306,

  # end of class arguments
  # ----------------------
  # begin class

) {

  # virtual resources for realising in their modules
  @docommon::fireport { "0${db_port} MySQL DB port":
    protocol => 'tcp',
    port => $db_port,
  }
  # if we've got a message of the day, include DB
  @domotd::register { "MySQL(${db_port})" : }

  # allow non-localhost connections to the mysql daemon
  domysqldb::configfile { 'mysql-openbind-dev':
    settings => {
      'mysqld' => {
        'bind-address'=> '0.0.0.0',
      },
    },
    notify_service => true,
  }
  # widen access for root user by cloning @localhost to @% row
  domysqldb::command::cloneuser { 'mysql-relax-root-dev':
    from_user => 'root',
    from_host => 'localhost',
    to_user => 'root',
    to_host => '%',
    require => [Class['domysqldb']],
  }

}

