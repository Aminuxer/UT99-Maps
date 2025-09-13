#!/bin/bash

ut1gamedir='/usr/games/ut99';
mapinfodir='/var/www/html/mapinfo';

cd $mapinfodir
echo "Found *.UNR files in $ut1gamedir , write infos to $mapinfodir"

for m in `ls -1 $ut1gamedir/Maps/*.unr`
do
  bn=`basename $m`
  sn=`echo $bn | cut -d '.' -f 1`
  szh=`du -h $m | cut -f 1`
  szb=`du -b $m | cut -f 1`
  dm=`stat -c '%y' "$m" | cut -d ' ' -f 1,2 | cut -b 1-19`
  hmd5=`md5sum $m | cut -d ' ' -f 1`
  hsha1=`sha1sum $m | cut -d ' ' -f 1`
  hsha256=`sha256sum $m | cut -d ' ' -f 1`

  mapdata=`$ut1gamedir/ucc AminGetMapInfo.AminGetMapInfo "$sn"`
  mititle=`echo -n "$mapdata\n" | grep Title | cut -d ':' -f 2 | cut -b 2-200`
  miauthor=`echo -n "$mapdata\n" | grep Author | cut -d ':' -f 2 | cut -b 2-200`
  mibestNM=`echo -n "$mapdata\n" | grep BestCount | cut -d ':' -f 2 | cut -b 2-200`
  mienterT=`echo -n "$mapdata\n" | grep EnterText | cut -d ':' -f 2 | cut -b 2-200`
  midefgam=`echo -n "$mapdata\n" | grep DefGameType | cut -d ':' -f 2 | cut -b 2-200`

  echo "<html><body bgcolor=#52545e text=#FFFFFF link=#00FF00 alink=#00BB00><h1>$sn</h1><br>" > $mapinfodir/$sn.htm;
  echo " FileName: <font color=\"#BAF000\"><B>$bn</B></font><br>" >> $mapinfodir/$sn.htm;
  echo " FileSize:     <font color=\"#BAF000\"><B>$szh</B></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;($szb bytes)<br>" >> $mapinfodir/$sn.htm;
  echo " Modified: <B>$dm</b><br><br>" >> $mapinfodir/$sn.htm;

  echo " Title:  <B>$mititle</B><br>" >> $mapinfodir/$sn.htm;
  echo " Author: <B>$miauthor</B><br>" >> $mapinfodir/$sn.htm;
  echo " BestCount: <font color=\"#BAF000\"><B>$mibestNM</B></font><br>" >> $mapinfodir/$sn.htm;
  echo " EnterText: <B>$mienterT</B><br>" >> $mapinfodir/$sn.htm;
  echo " Default GameType: <B>$midefgam</B><br><br>" >> $mapinfodir/$sn.htm;

  echo " MD5: <font color=\"#00F0BA\">$hmd5</font><br>" >> $mapinfodir/$sn.htm;
  echo " SHA-1: <font color=\"#00F0BA\">$hsha1</font><br>" >> $mapinfodir/$sn.htm;
  echo " SHA-256: <font color=\"#00F0BA\">$hsha256</font><br>" >> $mapinfodir/$sn.htm;
  echo "</body></html>" >> $mapinfodir/$sn.htm;
  echo " $sn OK";
done
