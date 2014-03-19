#
# clone a MySQL user within the user table
#
define domysqldb::command::cloneuser (

  $from_user = 'root',
  $from_host = 'localhost',
  $to_user = 'root',
  $to_host = '127.0.0.1',

) {

  domysqldb::command { "domysqldb-command-cloneuser-${title}" :
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
) SELECT '${to_user}', '${to_host}', Password
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
 WHERE User='${from_user}' AND Host='${from_host}'
ON DUPLICATE KEY UPDATE Host='${to_host}';",
    flush_privileges => true,
  }

}

