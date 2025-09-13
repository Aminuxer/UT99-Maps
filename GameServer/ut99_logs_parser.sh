#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "!! NO RUNNING game-servers from root;"
    exit 1
fi

LANG=C
loggs='/tmp/ut99/Logs';
prep='/opt/ut99';
prep2='/opt/ut992';

echo "Start UT 99 Log Parser..."
cd /usr/games/ut99/

# ./NetGamesUSA.com/ngWorldStats/bin/bgWorldStats
# ./NetGamesUSA.com/ngWorldStats/bin/ngWorldStats

# ## Convert Logs from UTF-16 to UTF-8 - more zero-bytes crash ngStatsUT !

for f in `find $loggs -type f -name 'Unreal.ngLog.20*.????.log'`
do
   echo " *** iconv   $f   utf16 -> utf8   ***"
   iconv -f utf16 -t utf8 $f > $f-utf8
   mv $f-utf8 $f
   cp $f $prep2
   mv $f $prep
done


# ## Run logs-2-db-2-html Java parser
strace ./NetGamesUSA.com/ngStats/ngStatsUT $prep 2>&1

sleep 5

# cp ./ASU/.htaccess ./Logs

