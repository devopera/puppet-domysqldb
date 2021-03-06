
class domysqldb::fixibdata (

  # class arguments
  # ---------------
  # setup defaults

  # log file is 5M by default
  $new_size = 5242880,

  $target_dir = '/tmp',
  $data_dir = $::mysql::params::datadir,
  # server_service_name incorrectly assumes mariadb for CentOS/RHEL7
  # $service_name = $::mysql::params::server_service_name,
  $service_name = 'mysqld',

) {

  $datetime = strftime("date_%Y-%m-%d_time_%H-%M-%S")

  # if the size has changed
  #   stop mysql (silently, as it may not be running)
  #   create a timestamped folder
  #   move the old ibdata files into it
  #   restart the service

  # disabled becuause not compatible with RHEL7
  exec { 'domysqldb-scrub-old-binlog-wrong-size' :
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "service ${service_name} stop > /dev/null 2>&1 ; mkdir ${target_dir}/puppet_ibdata_${datetime} && mv ${data_dir}/ib_logfile* ${target_dir}/puppet_ibdata_${datetime}/ && mv ${data_dir}/ibdata* ${target_dir}/puppet_ibdata_${datetime}/ && service ${service_name} start",
    # onlyif => "test `stat -c \'%s\' ${data_dir}/ib_logfile0` -ne ${new_size}",
    onlyif => false,
  }
  
}
