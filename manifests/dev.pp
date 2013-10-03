class domysqldb::dev (

  # class arguments
  # ---------------
  # setup defaults

  $db_port = 3306,

  # end of class arguments
  # ----------------------
  # begin class

) {

  @docommon::fireport { "0${db_port} MySQL DB port":
    protocol => 'tcp',
    port => $db_port,
  }
  mysql::server::config { 'mysql-openbind-dev':
    settings => {
      'mysqld' => {
        'bind-address'=> '0.0.0.0',
      },
    },
    notify_service => true,
    require => Class['mysql::server'],
  }
  # widen access for root user
  domysqldb::command { 'mysql-relax-root-dev':
    command => "UPDATE user SET Host='%' WHERE User='root' AND Host='localhost';",
    flush_privileges => true,
  }
  # if we've got a message of the day, include DB
  @domotd::register { "MySQL(${db_port})" : }

}

