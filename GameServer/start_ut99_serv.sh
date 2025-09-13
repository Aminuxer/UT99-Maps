#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "!! NO RUNNING game-servers from root;"
    exit 1
fi

# yum install libSDL-dev

echo "   current time stamp: "`date "+%Y-%m-%d %T"`

echo "Stop UT 99 Servers ..."
u=`/usr/bin/whoami`

echo "   pkill screen (1)"
ps -U $u -eo pid,cmd | grep SCREEN | grep UT99_ | awk '{print $1}' | xargs kill
screen -wipe

echo "   pkill ucc (1)"
pkill -U $u -15 ucc-bin
sleep 2
pkill -U $u -9 ucc-bin
sleep 5

echo "   pkill screen (2)"
ps -U $u -eo pid,cmd | grep SCREEN | grep UT99_ | awk '{print $1}' | xargs kill -9
screen -wipe


echo "   pack old ut99-sys-logs"
cd /tmp/ut99/tmp-System
rm -f ut99-sys-logs.tar.gz
tar --gzip -cf ut99-sys-logs.tar.gz _*.log *.ini
rm -f _*.log


echo "   pack and clean old ut99-game-logs"
cd /tmp/ut99/Logs
rm -f ut99-game-tmp-logs.tar.gz
tar --gzip -cf ut99-game-tmp-logs.tar.gz Unreal.ngLog.20*.????.tmp
find /tmp/ut99/Logs -type f -name "Unreal.ngLog.20*.????.tmp" -mtime +9 -delete


echo "Start UT 99 Servers ..."

cd /usr/games/ut99/

screen -dmS UT99_DM      /home/ut99/7777.sh

# ?mutator=BotPack.NoRedeemer  ?game=TTM-103-b45.TTM_Main3

