#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "!! NO RUNNING game-servers from root;"
    exit 1
fi

mutators='BDBMapVote304.BDBMapVote,NoInvisibility.NoInvisibility,EavySpawnProtectSDAVersion.EavySpawnProtectionSDA,MODOSUtilsV25.AutoRecorder,Hitsounds.Hitsounds,TeamColorOverlay_v1.TCOMutator,BrightPlayer2.BrightPlayer'
# ,DanesSkinManagerV2.DanesSkinManager 

while true
do
  dt=`date "+%Y-%m-%d %T"`
  echo "Start UT-99-DM at $dt ..."

  cd /usr/games/ut99/

  dm_map=`ls ./Maps/  | grep ^DM | sort -R | head -n 1 | cut -d '.' -f 1`

  ./ucc server "$dm_map?game=BotPack.DeathMatchPlus?mutator=$mutators -log=_DM.log ini=_UT_99_DM.ini"
  cp ~/.utpg/System/_DM.log /tmp/ut99/_DM_Crash_`date "+%Y-%m-%d--%H%M"`.log
  sleep 5

done


