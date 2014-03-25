
class domysqldb::cleanlogs (

  # class arguments
  # ---------------
  # setup defaults

  $settings,

) {

  # delete old log file if it is now redundant
  if (($settings['mysqld']['log_error'] != undef) and ($settings['mysqld']['log_error'] != '/var/log/mysqld.log')) {
    exec { 'domysqldb-cleanlogs-scrub-old-mysqld-log-file':
      path => '/bin:/usr/bin',
      command => 'rm /var/log/mysqld.log',
      onlyif => 'test -f /var/log/mysqld.log',
    }
  }

}
