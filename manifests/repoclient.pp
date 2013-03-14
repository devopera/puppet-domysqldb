class domysqldb::repoclient (

  # class arguments
  # ---------------
  # setup defaults

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
    ubuntu, debian: {
      # MySQL 5.5 is default for ubuntu 12.04
      package { 'common-mysqldb-five-five-install-clientonly':
        name => 'mysql',
        ensure => 'present',
      }
    }
  }

}

