domysqldb
=========

MySQL puppet config that requires mysql module

Changelog
---------

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
