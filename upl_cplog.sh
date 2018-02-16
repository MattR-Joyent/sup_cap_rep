#!/bin/bash
set +x
clear

# paths config
EXEPATH='/root/mattr/gdrive';
LOGPATH='/root/mattr/gdrive';
CSVPATH='/root/mattr/gdrive';

# location of 3rd party GDRIVE utility
GD="$EXEPATH/gdrive"

# read in the new folder value
NF=$(cat $LOGPATH/nf.out);
if [[ $(echo $NF | wc -m) -eq 0 ]]; then exit -1; fi;
echo "$(date +%T) - Folder ID: $NF";

# load log file into GDrive folder
LOGFILE="$(date +\%Y\%m\%d)_catrep.log"
echo "$(date +%T) - Uploading file $LOGFILE";
${GD} upload -p $NF $EXEPATH/$LOGFILE;

# remove nf file
rm $EXEPATH/nf.out;

# remove log file
rm $LOGPATH/$LOGFILE;

exit 0;