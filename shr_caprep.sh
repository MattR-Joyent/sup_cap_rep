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

SHREMAILS=$EXEPATH/share_emails

# read email addresses from file and share caprep folder
while read -r EMAIL
do
    echo "$(date +%T) - Sharing CapRep Folder to: $EMAIL";
    ${GD} share --role reader --type user --email $EMAIL $NF;
done < "$SHREMAILS";

exit 0;