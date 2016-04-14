#!/bin/bash

export LOGTO="FILE"
. `dirname $0`/../stdlib/stdlib.sh

# ./maildir_archive.sh X Y Z
#
# A script to archive maildir messages older than X from folder Y/Maildir to folder Z/Maildir
# 

DAYS_OLDERTHAN=$1
FROM_DIRECTORY=$2/Maildir/
GOTO_DIRECTORY=$3/Maildir/

function helpme
{
  echo "This script should have three arguments like so ./archive_off_X.sh X Y Z"
  echo "X is the number of days a file should be older than to archive"
  echo "Y is the directory containing ./Maildir/ from where we will archive"
  echo "Z is the directory containing ./Maildir/ to archive to"
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

echo Finding files in $FROM_DIRECTORY older than $DAYS_OLDERTHAN days to move out...

/usr/bin/find $FROM_DIRECTORY -type f -mtime +$DAYS_OLDERTHAN -printf "%P\n" | grep "/cur/" | while read -d $'\n' FILENAM
do
  #
  # Find where we are going to copy to and check for a duplicate file 
  #
  ARCHSTR=""
  if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
  then
    ARCHSTR=".dupe-`date +%Y%m%d`"
    if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
    then
      ARCHSTR=".dupe-`date +%Y%m%d%H%M`"
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
  if [[ ! -d "$NEWDIR" ]]
  then
    mkdir -p "$NEWDIR"
  fi

  #
  # Move out the files
  # 
  echo Moving $FROM_DIRECTORY$FILENAM $NEWDIR/
  mv "$FROM_DIRECTORY$FILENAM" "$NEWDIR/"	  
done

echo Mail Move Done
echo Finding directories

/usr/bin/find $FROM_DIRECTORY -maxdepth 1 -name ".*" -type d -printf "%P\n" | sort | grep -v "^\.Sent\|^\.Draft\|^\.Trash\|^\.Delete\|^\.Notes\|^\.Junk" | while read -d $'\n' DIRNAM
do
	DTEST1=$(ls -1A "$FROM_DIRECTORY$DIRNAM/new/" | wc -l)
	DTEST2=$(ls -1A "$FROM_DIRECTORY$DIRNAM/cur/" | wc -l)

	if [ $DTEST1 -eq 0 ]; then
	 	if [ $DTEST2 -eq 0 ]; then
		     ARCHSTR=".MovedEmptyFolders.Base"
		     if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
		     then
		       ARCHSTR=".MovedEmptyFolders.dupe-`date +%Y%m%d`"
		       if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
		       then
		         ARCHSTR=".MovedEmptyFolders.dupe-`date +%Y%m%d%H%M`"
		         if [[ -e "$GOTO_DIRECTORY$ARCHSTR$FILENAM" ]]
		         then
		           #ignore the file
		           echo Hit a duplicate for this file $FILENAM
		           continue
		         fi
		       fi
		     fi
			 
		     NEWDIR="$GOTO_DIRECTORY$ARCHSTR$DIRNAM"
			 
		     #
		     # Move out the directory
		     # 
		     echo Moving $FROM_DIRECTORY$DIRNAM $NEWDIR
		     mv "$FROM_DIRECTORY$DIRNAM" "$NEWDIR"		 
	 	fi
	fi
done

echo Empty Maildir Move Done

chown -R simon-archive.simon-archive $GOTO_DIRECTORY
chmod -R o-rwx $GOTO_DIRECTORY
#