# run a MySQL script once on a new system
define domysqldb::runonce (
  # @param command {string} name of script file to run
  $command = $title,
  $notifier_dir = '/etc/puppet/tmp',
) {
  # run script as mysql root
  exec { "exec-${title}" :
    command => "/usr/bin/mysql -u root --password='${::domysqldb::root_password}' < $command && touch ${notifier_dir}/puppet-domysqldb-runonce-${title}",
    creates => "${notifier_dir}/puppet-domysqldb-runonce-${title}",
  }
}

