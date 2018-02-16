#!/bin/bash
set +x
clear

# setup runtime profile
source /root/.profile
source /root/jaybox

# paths config
EXEPATH='/root/mattr/gdrive';
LOGPATH='/root/mattr/gdrive';
CSVPATH='/root/mattr/gdrive';

# date which will become the folder name
FD="SPC_CAPREP_$(date +"%Y%m%d")"
echo "$(date +%T) - Todays folder will be: $FD"

# UUID for the parent folder currently GoogleDrive/mattr/CapacityReporting
PF="1SO7XJrwrHUEANnY5CzTuxQBAaPjvJ1q1"

# location of 3rd party GDRIVE utility
GD="$EXEPATH/gdrive"

# location of reporting script
SS='/root/spc-servers'

# if todays folder exists remove it first (else GD creates multiple versions!
FOLDEREXISTS=$(${GD} list -q "mimeType='application/vnd.google-apps.folder' and name='$FD' and trashed=false" --no-header | wc -l)

if [[ "$FOLDEREXISTS" -ne 0 ]]; then

        FOLDERID=$(${GD} list -q "mimeType='application/vnd.google-apps.folder' and name='$FD' and trashed=false" --no-header | awk '{print $1}');
        FOLDERNAME=$(${GD} list -q "mimeType='application/vnd.google-apps.folder' and name='$FD' and trashed=false" --no-header | awk '{print $2}');
        echo "$(date +%T) - Remove the existing folder - $FOLDERNAME"

        if [[ $(echo $FOLDERID | wc -m) -ne 0 ]]; then
                DELETERET=$(${GD} delete --recursive $FOLDERID);
                echo "$(date +%T) - $DELETERET";
         else
                echo "$(date +%T) - PROCESS STOPPED: Unable to remove folder: $FOLDERNAME ($FOLDERID)";
                exit -1;
         fi
fi

# use gdrive to make a folder in Goggle Drive
echo "$(date +%T) - Creating folder - Name: $FD"
NF_RET=$(${GD} mkdir -p $PF $FD);

# keep the folder UUID safe for use in a minute to upload CSV files
NF=$(echo $NF_RET | awk '{print $2}');
echo "$(date +%T) - Folder created - ID: $NF"
echo $NF > $EXEPATH/nf.out;

# curl for call to CNAPI
CURL="curl -4 --connect-timeout 10 -sS -i -H accept:application/json -H content-type:application/json -H 'accept-version: *' --url";

for DC in $AZS;
# for DC in east_1a;
do
        CNAPI_EP=$(eval echo \$${DC}_CNAPI);
        MYCNAPI="$CURL $CNAPI_EP/servers";
        echo "$(date +%T) - Processing...$DC";
        ${SS} -a $DC -K -c -n $($MYCNAPI | json -Ha hostname -c 'this.traits.ssd == true || this.traits.storage == true || Object.keys(this.traits).length === 0' -c 'this.setup == true' -c 'this.hostname != "headnode"' | tr '\n' ',') > $CSVPATH/$DC.csv;

        echo "$(date +%T) - Uploading file $DC.csv";
        ${GD} upload -p $NF $CSVPATH/$DC.csv;
done;

# validate that the file exists
for DC in $AZS;
# for DC in east_1a;
do
        echo "$(date +%T) - Verifying $DC.csv found in Google Folder...";
        FILEEXISTS=$(${GD} list -q "name='$DC.csv' and trashed=false and '$NF' in parents" --no-header | wc -l);

        if [[ "$FILEEXISTS" -eq 0 ]]; then
                echo "$(date +%T) - PROBLEM: $DC.csv has NOT been found in the Google Folder: $NF";
                INERROR=1;
        else
                echo "$(date +%T) - Verified.  Removing local file - $DC.csv";
                rm $CSVPATH/$DC.csv;
        fi;
done;

if [[ "$INERROR" -eq 1 ]]; then
        echo "$(date +%T) - Process FAILED";
        exit -1;
fi;

echo "$(date +%T) - Process completed SUCCESSFULLY";
exit 0;