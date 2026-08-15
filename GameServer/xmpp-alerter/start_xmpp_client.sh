#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "!! NO RUNNING chat client from root;"
    exit 1
fi

SrvRoom='XMPP'
datee=`date "+%Y-%m-%d %T"`

u=`/usr/bin/whoami`

pkill -U $u xmpp-muc-client
pkill -U $u "bot"
pkill -U $u "inotify"
screen -wipe
sleep 1

echo "Start XMPP client in screen ($SrvRoom)"
screen -dmS $SrvRoom ~/xmpp-alerter/xmpp-muc-client.py
sleep 2

screen -S $SrvRoom -X stuff "Detect restart at $datee !
";


echo "Start Demo monitoring bot..."
/home/$u/xmpp-alerter/watcher_demos_bot.sh &

echo "OK"
