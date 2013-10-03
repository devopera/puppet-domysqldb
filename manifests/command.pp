define domysqldb::command (

  # class arguments
  # ---------------
  # setup defaults

  # command must finish with a semi-colon
  $command,
  $user = 'root',
  $password = undef,
  $database = 'mysql',
  $home_dir = '/root',
  $flush_privileges = false,

  # end of class arguments
  # ----------------------
  # begin class

) {

  if ($user == undef) {
    # don't insert a username
    $expr_user = ''
  } else {
    $expr_user = " --user='${user}' "
  }

  if ($password == undef) {
    # don't insert a password
    $expr_password = ''
  } else {
    $expr_password = " --password='${password}' "
  }

  if ($database == undef) {
    # don't name a database
    $expr_database = ''
  } else {
    $expr_database = " --database='${database}' "
  }
  
  if ($flush_privileges == false) {
    # don't insert an additional expression
    $expr_addon = ''
  } else {
    $expr_addon = ' flush privileges;'
  }

  # run command using command line exec
  # explicitly set HOME directory to allow for ~/.my.cnf
  exec { "domysqldb-command-${title}" :
    path => '/usr/bin:/bin',
    command => "bash -c \"export HOME='${home_dir}'; mysql ${expr_user} ${expr_password} ${expr_database} --execute=\\\"${command} ${expr_addon}\\\" \"",
  }

}

