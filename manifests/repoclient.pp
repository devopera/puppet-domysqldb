class domysqldb::repoclient (

  # class arguments
  # ---------------
  # setup defaults

  # type can be 'mysql', 'percona' or 'mariadb'
  $db_type = 'mysql',

  # version can be '5.5' or '5.6', though not all types are supported
  $db_version = '5.5',

  # end of class arguments
  # ----------------------
  # begin class

) {

  case $db_type {
    mysql: {

      case $db_version {
        '5.5': {
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
        } # /5.5

        '5.6': {
          # install MySQL repository to get MySQL 5.6 on Centos
          case $operatingsystem {
            centos, redhat: {
              exec { "domysqldb-repo-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'rpm -Uvh http://repo.mysql.com/mysql-community-release-el6.rpm',
                user => 'root',
                creates => '/etc/yum.repos.d/mysql-community.repo',
              }->
              exec { "domysqldb-install-clientonly-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'yum -y install mysql-community-client',
              }
              # redundant but allow mysql class to create package resource
              $package_name = undef
            }
          } # /operatingsystem
        } # /5.6
      } # /db_version
    } # /mysql
  } # /db_type

  class { 'mysql::client':
    package_name => $package_name,
  }

}

