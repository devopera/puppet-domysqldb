[devopera](http://devopera.com)-[domysqldb](http://devopera.com/module/domysqldb)
===============

MySQL is the cornerstone of the Linux-Apache-MySQL-PHP (LAMP) stack.  It's the single most popular open-source database engine.  This Devopera install configures both client and server, including dynamically-allocated server settings to maximise MySQL performance for each host type.

Changelog
---------

2014-09-12

  * Changed paths to use mysql::params, following move from /etc/mysql/conf.d to /etc/my.cnf.d

2014-06-24

  * Tidied up module for release open source

2014-04-03

  * Fixed Facter change from 1.7.5 to 2.0.1, where certain facts were removed

2014-03-25

  * Refactored to clean out dangerous ibdata resize code.

2014-03-11

  * Modified to work with latest puppetlabs-mysql module.  ${::root_home} used for command.pp calls. Safer creation of root@% user in dev profile.

2013-10-10

  * Parameterised $timeout_restart to allow for really big databases to startup

2013-10-03

  * Added ::dev profile that opens up access to MySQL for dev machines
  * Added ::command macro for running MySQL commands

2013-04-10

  * When the log files change size, the old ibdata/ib_logfiles now get moved to a safe (temporary) store in /tmp, rather than being deleted.

2013-03-01

  * Got rid of dynamic settings.  All settings are set normally using the $settings array.  If settings are undefined, sensible dynamic values are calculated.

2013-02-25

  * Modified runonce to write notifications to a parameterised ${notifier_dir}.
  * Added mysql-devel to the list of 5.5 packages installed.

Usage
-----

Setup MySQL server

    class { 'domysqldb' : }

Setup with a given root password

    class { 'domysqldb':
      root_password => 'admLn**',
    }

Override given settings for each mysql component, e.g. key_buffer_size for mysqld

    class { 'domysqldb':
      root_password => 'admLn**',
      settings => {
        'mysqld' => {
          'key_buffer_size' => '32M',
        }
      }
    }

Tell MySQL to use a fixed buffer size, not to derive it as a fraction of available RAM (default behaviour)
    class { 'domysqldb':
      root_password => 'admLn**',
      settings => {
        'mysqld' => {
          'innodb_buffer_pool_size' => '512M',
        }
      }
    }

Operating System support
------------------------

Tested with CentOS 6, Ubuntu 12.04

Copyright and License
---------------------

Copyright (C) 2012 Lightenna Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
