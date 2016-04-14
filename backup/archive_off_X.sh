#!/bin/bash -e

export LOGTO="FILE"
. /usr/local/scripts/root/stdlib.sh

# ./archive_off_X.sh X Y Z
#
# A script to archive files (not directories) older than X from folder Y to folder Z
# 


DAYS_OLDERTHAN=$1
FROM_DIRECTORY=$2
GOTO_DIRECTORY=$3

function helpme
{
  echo "This script should have three arguments like so ./archive_off_X.sh X Y Z"
  echo "X is the number of days a file should be older than to archive"
  echo "Y is the directory from where we will archive"
  echo "Z is the directory to archive to"
  exit
}

if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters"
    helpme
fi

if [[ ! -d "$FROM_DIRECTORY" ]]
then
    echo "From directory supplied do not exist"
    helpme
fi

if [[ ! -d "$GOTO_DIRECTORY" ]]
then
    echo "To directory supplied do not exist"
    helpme
fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

echo Finding files in $FROM_DIRECTORY to move out...

/usr/bin/find $FROM_DIRECTORY -type f -mtime +$DAYS_OLDERTHAN -print0 | while read -d $'\0' FILENAM
do
  #
  # Find where we are going to copy to and check for a duplicate file 
  #
  ARCHSTR="/base/"
  if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
  then
    ARCHSTR="/dupe-`date +%Y%m%d`/"
    if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
    then
      ARCHSTR="/dupe-`date +%Y%m%d%H%M`/"
      if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
      then
        #ignore the file
        echo Hit a duplicate for this file $FILENAM
        continue
      fi
    fi
  fi
  
  # Make sure our new directory exists
  #
  NEWDIR=$GOTO_DIRECTORY$ARCHSTR`dirname "$FILENAM"` 
  if [[ ! -d $NEWDIR ]]
  then
    mkdir -p $NEWDIR
  fi
  
  #
  # Move out the file
  # 
  echo Moving $FILENAM $NEWDIR/`basename $FILENAM`
  mv $FILENAM $NEWDIR/`basename $FILENAM`
  
done
IFS=$SAVEIFS

#