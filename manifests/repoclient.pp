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

  case $db_type {
    mysql: {

      case $db_version {
        '55': {
          # install REMI repository to get MySQL 5.5 on Centos 6
          case $operatingsystem {
            centos, redhat: {
              exec { "domysqldb-repo-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm',
                user => 'root',
                creates => '/etc/yum.repos.d/remi.repo',
              }->
              exec { "domysqldb-install-clientonly-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'yum -y --enablerepo=remi,remi-test install mysql',
              }
              # redundant but allow mysql class to create package resource
              $package_name = undef
            }
            fedora: {
              # on fedora we install maria
              $package_name = 'mariadb'
            }
            ubuntu, debian: {
              # MySQL 5.5 is default for ubuntu 12.04
              $package_name = undef
            }
          } # /operatingsystem
        } # /55

        '56': {
          # install MySQL repository to get MySQL 5.6 on Centos
          case $operatingsystem {
            centos, redhat: {
              exec { "domysqldb-repo-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'rpm -Uvh http://repo.mysql.com/mysql-community-release-el6.rpm',
                user => 'root',
                # @todo see what this created in yum.repos.d, then edit below
                # creates => '/etc/yum.repos.d/remi.repo',
              }->
              exec { "domysqldb-install-clientonly-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'yum -y install mysql-community-client',
              }
              # redundant but allow mysql class to create package resource
              $package_name = undef
            }
          } # /operatingsystem
        } # /56
      } # /db_version
    } # /mysql
  } # /db_type

  class { 'mysql::client':
    package_name => $package_name,
  }

}

