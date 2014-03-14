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
  domysqldb::command { 'mysql-relax-root-dev':
    # command => "UPDATE user SET Host='%' WHERE User='root' AND Host='localhost';,
    command => "INSERT INTO user (User, Host, Password
, Select_priv, Insert_priv, Update_priv, Delete_priv, Create_priv
, Drop_priv, Reload_priv, Shutdown_priv, Process_priv
, File_priv, Grant_priv, References_priv
, Index_priv, Alter_priv
, Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv
, Execute_priv
, Repl_slave_priv, Repl_client_priv
, Create_view_priv, Show_view_priv
, Create_routine_priv, Alter_routine_priv
, Create_user_priv
, Event_priv, Trigger_priv
, Create_tablespace_priv
, max_questions, max_updates, max_connections, max_user_connections
) SELECT User, '%', Password
, Select_priv, Insert_priv, Update_priv, Delete_priv, Create_priv
, Drop_priv, Reload_priv, Shutdown_priv, Process_priv
, File_priv, Grant_priv, References_priv
, Index_priv, Alter_priv
, Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv
, Execute_priv
, Repl_slave_priv, Repl_client_priv
, Create_view_priv, Show_view_priv
, Create_routine_priv, Alter_routine_priv
, Create_user_priv
, Event_priv, Trigger_priv
, Create_tablespace_priv
, max_questions, max_updates, max_connections, max_user_connections
 FROM user
 WHERE User='root' AND Host='localhost'
ON DUPLICATE KEY UPDATE Host='%';",
    flush_privileges => true,
    require => Class['domysqldb'],
  }

}

