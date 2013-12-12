class domysqldb::repoclient (

  # class arguments
  # ---------------
  # setup defaults

  # type can be 'percona' or 'mariadb'
  $db_type = 'mysql',

  # version can be 55 or 56, though not all types are supported
  $db_version = '55',

  # end of class arguments
  # ----------------------
  # begin class

) {

  # install REMI repository to get MySQL 5.5 on Centos 6
  case $operatingsystem {
    centos, redhat: {
      exec { 'common-mysqldb-five-five-repo' :
        path => '/usr/bin:/bin',
        command => 'rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm',
        user => 'root',
        creates => '/etc/yum.repos.d/remi.repo',
      }->
      exec { 'common-mysqldb-five-five-install-clientonly' :
        path => '/usr/bin:/bin',
        command => 'yum -y --enablerepo=remi,remi-test install mysql',
      }
    }
    fedora: {
      # on fedora we install both client and server because there's no client-only package
      package { 'common-mysqldb-five-five-install-clientonly':
        name => 'mariadb',
        ensure => 'present',
      }
    }
    ubuntu, debian: {
      # MySQL 5.5 is default for ubuntu 12.04
#      package { 'common-mysqldb-five-five-install-clientonly':
#        name => 'mysql-client',
#        ensure => 'present',
#      }
    }
  }

}

