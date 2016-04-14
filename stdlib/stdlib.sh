#!/bin/bash

#
# This script contains functions used by a number of scripts
#
# If the variable LOGTO is set to "FILE" in a script it will suppress the console output of all scripts (great for cron)
# If the variable LOGEMAIL is set to an array of email addresses in the script, the emails will be sent the log after completion
# If the variable LOGEMAILERRORONLY is set to "TRUE" in the script, the emails will only be sent the log if there are any errors
#
# If the variable NOEXITONERROR is set to "TRUE" the the script will not abort on errors (but they will be logged)
#
#

#
# Functions
#
stdlib_startscript() {
  START_DATE=`date`
  echo `basename $0` $@ run by $SLOGNAM as $SWHOAMI is running with pid $$ at `date` >> $MYLOG
  $LOGGER `basename $0` $@ run by $SLOGNAM as $SWHOAMI is running with pid $$ at `date`
}

stdlib_stopscript() {
  STOP_DATE=`date`
  echo `basename $0` $@ run by $SLOGNAM as $SWHOAMI is stopped `date` >> $MYLOG
  $LOGGER `basename $0` $@ run by $SLOGNAM as $SWHOAMI is stopped `date`
  if [ -z "$LTESUBJ" ]
  then
    LTESUBJ="Script on `hostname` - `basename $0` $@"
  fi
  stdlib_logtoemail
  stdlib_logtojson
}

stdlib_killscript() {
  echo `basename $0` $@ run by $SLOGNAM as $SWHOAMI is killed `date` >> $MYLOG
  $LOGGER `basename $0` $@ run by $SLOGNAM as $SWHOAMI is killed `date`
  LTESUBJ="Script Killed on `hostname` - `basename $0` $@"  
  LTEERR="True"
  exit $?
  # A killed script will then proceed to the stopscript function as well
}

stdlib_scripterr() {
  if [ "$NOEXITONERROR" = "TRUE" ]
  then
    echo `basename $0` $@ with pid $$ run by $SLOGNAM as $SWHOAMI had an error on `caller` and is continuing `date` >> $MYLOG
    $LOGGER `basename $0` $@ with pid $$ run by $SLOGNAM as $SWHOAMI  had an error on `caller` and is continuing `date` `date`
    LTESUBJ="Script Error on `hostname` - `basename $0` $@"
    LTEERR="True"
  else 
    echo `basename $0` $@ with pid $$ run by $SLOGNAM as $SWHOAMI had an error on `caller` and aborted `date` >> $MYLOG
    $LOGGER `basename $0` $@ with pid $$ run by $SLOGNAM as $SWHOAMI had an error on `caller` and aborted `date` `date`
    LTESUBJ="Script Aborted on `hostname` - `basename $0` $@"
    LTEERR="True"
    exit 999
  fi
}

stdlib_logtofile() {
  exec >> $MYLOG
  exec 2>&1
}

stdlib_logtojson() {
  HOSTN=`/bin/hostname`
  SCRIPTN=`basename $0`
  d1=$(date -d "$START_DATE" +%s)
  d2=$(date -d "$STOP_DATE" +%s)
  RUNTIME=$((d2 - d1))
  LOGTEXT=`cat $MYLOG | $PYTHON -c 'import json,sys; print json.dumps(sys.stdin.read())'`
  echo "{ \"script_start\": \"$START_DATE\", \"script_stop\": \"$STOP_DATE\", \"script_name\": \"$SCRIPTN\", \"script_runtime\": \"$RUNTIME\", \"host\": \"$HOSTN\", \"pid\": \"$$\",  \"LOGTO\": \"$LOGTO\", \"LOGEMAIL\": \"$LOGEMAIL\", \"LTEERR\": \"$LTEERR\", \"LOGEMAILERRORONLY\": \"$LOGEMAILERRORONLY\", \"NOEXITONERROR\": \"$NOEXITONERROR\", \"whoami\": \"$SWHOAMI\", \"logname\": \"$SLOGNAM\", \"logfile\": \"$MYLOG\", \"logtext\": $LOGTEXT }" >> /var/log/scripts/json/`date +%Y%m%d`.json
  
}

stdlib_logtoemail() {
  if [ -n "$LOGEMAIL" ]
  then
    if [ "$LOGEMAILERRORONLY" = "TRUE" ]
    then
      if [ -n "$LTEERR" ]
      then
        stdlib_maillognow
      fi
    else
      stdlib_maillognow
    fi
  fi
}

stdlib_logtoboth() {
  exec &> >(tee -a $MYLOG)
}

stdlib_maillognow() {
  for LTESA in "${LOGEMAIL[@]}"
  do
    cat $MYLOG | mail -s "$LTESUBJ" $LTESA
  done
}


#
# End of Functions
#

# Grabbing whoami and logname before we do redirection
SWHOAMI=`/usr/bin/whoami`
SLOGNAM=`/usr/bin/logname 2>&1`

# Get Program file location
LOGGER=`/usr/bin/which logger`
PYTHON=`/usr/bin/which python`

# Lets abort on a failed command
trap stdlib_scripterr ERR

# This is where I should log to.
mkdir -p /var/log/scripts
mkdir -p /var/log/scripts/json
MYLOG=/var/log/scripts/`basename $0`-`date +%Y%m%d%H%M%S`-$$.log

#
# If LOGTO is set to "FILE" then we should just dump the logs to a file... great for cron!
# Else we'll append the log to a script and bounce it to the console as well.
#
if [ "$LOGTO" = "FILE" ]
then
  stdlib_logtofile
else 
  stdlib_logtoboth
fi

# Make sure we notice exits
trap stdlib_stopscript EXIT
trap stdlib_killscript SIGHUP SIGINT SIGTERM

# log the startup
stdlib_startscript