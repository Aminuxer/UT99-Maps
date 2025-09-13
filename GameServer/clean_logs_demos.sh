#!/bin/sh

cd /usr/games/ut99

find ./Demos/ -type f -name "*.dem" -mtime +5 -delete
screen -S XMPP -X stuff "Server-side demos older 5 days deleted !
";

find ./Logs -type f -name "Unreal.ngLog.20*.????.tmp" -mtime +9 -delete

find /tmp/ut99/Logs -type f -name "Unreal.ngLog.20*.????.tmp" -mtime +9 -delete

find /opt/ut992 -type f -name "Unreal.ngLog.????.??.??.??.??.??.????.log" -mtime +32 -delete


cd /tmp/ut99/tmp-System
rm -f ut99-sys-logs.tar.gz
tar --gzip -cf ut99-sys-logs.tar.gz _*.log *.ini
rm -f _*.log

cd /tmp/ut99/Logs
rm -f ut99-game-tmp-logs.tar.gz
tar --gzip -cf ut99-game-tmp-logs.tar.gz Unreal.ngLog.20*.????.tmp
find /tmp/ut99/Logs -type f -name "Unreal.ngLog.20*.????.tmp" -mtime +9 -delete
