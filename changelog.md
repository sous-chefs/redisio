redisio CHANGE LOG
===

1.0.3 - Released 5/2/2012
---

  - Added changelog.md
  - Added a bunch more configuration options that were left out (default values left as they were before):
      databases
      slaveservestaledata
      replpingslaveperiod
      repltimeout
      maxmemorysamples
      noappendfsynconwrite
      aofrewritepercentage
      aofrewriteminsize
      
      It is worth nothing that since there is a configurable option for conf include files, and the fact that redis uses the most recently read configuration option... even if a new option where to show up, or and old one was not included they could be added using that pattern.
      

1.0.2 - Released 4/25/2012
---

 - Merged in pull request from meskyanichi which improved the README.md and added a .gitignore
 - Added a "safe_install" node attribute which will prevent redis from installing anything if it exists already.  Defaults to true.
 - Addedd a "redis_gem" recipe which will install the redis gem from ruby gems, added associated attributes.  See README for me

1.0.1 - Released 4/8/2012
---

 - Added some prequisite checks for RHEL based distributions
 - Minor typos and formatting fixes in metadata.rb and README.md

1.0.0 - Released 4/8/2012
---

 - Initial Release
