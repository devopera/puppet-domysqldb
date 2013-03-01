domysqldb
=========

MySQL puppet config that requires mysql module

Changelog
---------

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