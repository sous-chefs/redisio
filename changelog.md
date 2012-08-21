redisio CHANGE LOG
===

1.1.0 - Released 8/21/2012
---
  ! Warning breaking change !: The redis pidfile directory by default has changed, if you do not STOP redis before upgrading to the new version
                               of this cookbook, it will not be able to stop your instance properly via the redis service provider, or the init script.
                               If this happens to you, you can always log into the server and manually send a SIGTERM to redis

  - Changed the init script to run redis as the specified redis user
  - Updated the default version of redis to 2.4.16
  - Setup a new directory structure for redis pid files.  The install provider will now nest its pid directories in base_piddir/<port number>/redis_<port>.pid.
  - Added a RedisioHelper module in libraries.  The recipe_eval method inside is used to wrap nested resources to allow for the proper resource update propigation.  The install provider uses this.
  - The init script now properly respects the configdir attribute
  - Changed the redis data directories to be 775 instead of 755 (this allows multiple instances with different owners to write their data to the same shared dir so long as they are in a common group)
  - Changed default for maxclients to be 10000 instead of 0.  This is to account for the fact that maxclients no longer supports 0 as 'unlimited' in the 2.6 series
  - Added logic to replace hash-max-ziplist-entries, hash-max-ziplist-value with  hash-max-zipmap-entires, hash-max-zipmap-value when using 2.6 series 
  - Added the ability to log to any file, not just syslog.  Please do make sure after you set your file with the logfile attribute you also set syslogenabled to 'no'

1.0.3 - Released 5/2/2012
---

  - Added changelog.md
  - Added a bunch more configuration options that were left out (default values left as they were before):  
      - databases
      - slaveservestaledata
      - replpingslaveperiod
      - repltimeout
      - maxmemorysamples
      - noappendfsynconwrite
      - aofrewritepercentage
      - aofrewriteminsize
      
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
