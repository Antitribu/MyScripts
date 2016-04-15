#!/bin/bash
#

# If the running agents PID is lest than the mmin old we should give it more time.
MMIN=59
LMIN=180
PIDLOC="/var/run/puppet/agent.pid"
RUNLOC="/var/lib/puppet/state/agent_catalog_run.lock"

#
# Check that the agent lock isn't there longer than is reasonable
#
if [ -f $RUNLOC ]; then
  if [ -f $PIDLOC ]; then
    /usr/bin/logger "Puppet appears to be running."   
  else
    RT=`find $RUNLOC -mmin +$LMIN |wc -l`
    if [ $RT -gt 0 ]; then
      /usr/bin/logger "Puppet agent lock file isn't right, making very sure puppet is dead then removing it."     
      /usr/bin/killall puppet
      /usr/bin/killall -9 puppet
      /bin/sleep 30
      rm $RUNLOC -f
    else
      /usr/bin/logger "Puppet lock file exist however it is less than $LMIN minutes old"   
    fi
  fi
fi

#
# Check the pid isn't there for more than $MMIN
#
if [ -f $PIDLOC ]; then
  RT=`find $PIDLOC -mmin +$MMIN |wc -l`
  if [ $RT -gt 0 ]; then
    /usr/bin/logger "Puppet is killed after running too long."     
    /usr/bin/killall puppet
    /bin/sleep 30
  else
    /usr/bin/logger "Puppet is still running less than $MMIN minutes."   
  fi
fi

#
# If the Pid doesn't exist start up puppet
#
if [ ! -f $PIDLOC ]; then
  /usr/bin/logger "Puppet starting from script with the hostname `hostname`"   
  /usr/bin/puppet agent --onetime --logdest syslog
fi
