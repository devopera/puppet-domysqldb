class domysqldb::params {

  case $operatingsystem {
    centos, redhat, fedora: {
      $service_name = 'mysqld'
    }
    ubuntu, debian: {
      $service_name = 'mysql'
    }
  }

}

