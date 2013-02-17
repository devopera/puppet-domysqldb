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

