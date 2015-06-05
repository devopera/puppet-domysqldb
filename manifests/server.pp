class domysqldb::server (

  # class arguments
  # ---------------
  # setup defaults

  # type can be 'mysql', 'percona' or 'mariadb'
  $db_type = 'mysql',

  # version can be 5.5 or 5.6, though not all types are supported
  $db_version = '5.5',

  # end of class arguments
  # ----------------------
  # begin class

) {

  case $db_type {
    mysql: {

      case $db_version {
        '5.5': {

          case $operatingsystem {
            centos, redhat: {
              exec { "domysqldb-server-install-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'yum -y --enablerepo=remi,remi-test install mysql-server mysql-devel',
                before => Class['mysql::client'],
              }
              $package_name = undef
            }
        
            ubuntu, debian: {
              # MySQL 5.5 is default in 12.04
              # but can't install with package because of mysql module conflict
              # package { 'mysql-server' :
              #   ensure => 'present',
              # }->
              exec { "domysqldb-server-install-${db_version}" :
                path => '/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
                command => 'apt-get -y -q -o DPkg::Options::=--force-confold install mysql-server',
                before => Class['mysql::client'],
              }->
              # install other packages (required for python pip installs)
              package { 'libmysqlclient-dev' :
                ensure => present,
              }
              $package_name = undef
            }
        
            fedora: {
              $package_name = 'mariadb-server'
              exec { 'domysqldb-mysql-create-user-group-manually' :
                path => '/bin:/usr/bin:/sbin:/usr/sbin',
                command => 'groupadd mysql && useradd -r -g mysql mysql',
                before => [Anchor['domysqldb-pre-server-install']],
                # only add user if not already there
                onlyif => 'test `/bin/egrep  -i "^mysql" /etc/passwd | wc -l` == 0',
              }
            } # /fedora 
          } # /operatingsystem
        } # /5.5

        '5.6': {

          case $operatingsystem {
            centos, redhat: {
              exec { "domysqldb-server-install-${db_version}" :
                path => '/usr/bin:/bin',
                command => 'yum -y install mysql-community-server mysql-community-devel',
                before => Class['mysql::client'],
              }
              $package_name = undef
            }
          } # /operatingsystem

        }
      } # /db_version
    } # /mysql
  } # /db_type

  # configure mysql server
  anchor { 'domysqldb-pre-server-install' : }
  
}

