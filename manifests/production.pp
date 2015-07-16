class domysqldb::production (

  # class arguments
  # ---------------
  # setup defaults

  $db_port = 3306,

  # end of class arguments
  # ----------------------
  # begin class

) {

  # if we've got a message of the day, include DB
  @domotd::register { "MySQL[${db_port}]" : }

}

