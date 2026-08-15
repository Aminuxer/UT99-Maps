#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "!! NO RUNNING demo monitor from root;"
    exit 1
fi

SrvRoom='XMPP';
demdir='/opt/ut99/Demos';

pkill demos_bot
pkill -9 demos_bot
pkill inotifywait
pkill -9 inotifywait

cd $demdir

IFS='
'
echo "Start Demo monitoring bot in $demdir;"
/usr/bin/inotifywait -e create,close_write --format '%f %:e' --include '\.dem$' -m $demdir |\
(
while read
do
    echo "R $REPLY";
    FILE=$(echo $REPLY | cut -f 1 -d ' ')
    METHOD=$(echo $REPLY | cut -f 2 -d ' ' | cut -d ':' -f 1)

    if [[ $METHOD == 'CREATE' ]]; then
       line="New game-match started: "`basename $FILE .dem | tr '_' ' '`
    elif [[ $METHOD == 'CLOSE_WRITE' ]]; then
       line=" .. Match finished! Server demo: https://ut99.my.game-server.ltd/demo/$FILE"
    else
       line=" ... Call $METHOD to $FILE ...!";
    fi

    echo "   F $FILE M $METHOD L $line";
    screen -S $SrvRoom -X stuff "$line
";
done
)
