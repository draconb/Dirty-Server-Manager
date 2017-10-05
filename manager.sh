#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
#http://stackoverflow.com/questions/242538/unix-shell-script-find-out-which-directory-the-script-file-resides
#Pull values from config INI
sed -i 's/^+//g' ${SCRIPTPATH}/manager-config.ini
source <(grep = ${SCRIPTPATH}/manager-config.ini)
#sed "s/;/#/g" manager-config.ini | source /dev/stdin
MAX_PLAYERS=`echo ${MAX_PLAYERS} | sed -e 's/\r//g'`
GALAXY=`echo ${GALAXY} | sed -e 's/\r//g'`
GalaxyDirectory=`echo ${GalaxyDirectory} | sed -e 's/\r//g'`
PARAMS=`echo ${PARAMS} | sed -e 's/\r//g'`
PORT=`echo ${PORT} | sed -e 's/\r//g'`
Listed=`echo ${Listed} | sed -e 's/\r//g'`
SteamQueryPort=`echo ${SteamQueryPort} | sed -e 's/\r//g'`
SteamMasterPort=`echo ${SteamMasterPort} | sed -e 's/\r//g'`
GameIPAddress=`echo ${GameIPAddress} | sed -e 's/\r//g'`
RconIPAddress=`echo ${RconIPAddress} | sed -e 's/\r//g'`
RconPassword=`echo ${RconPassword} | sed -e 's/\r//g'`
RconPort=`echo ${RconPort} | sed -e 's/\r//g'`
LOG_ROTATION=`echo ${LOG_ROTATION} | sed -e 's/\r//g'`
AutoRestart=`echo ${AutoRestart} | sed -e 's/\r//g'`
DAILYRESTART=`echo ${DailyRestart} | sed -e 's/\r//g'`
BETA=`echo ${BETA} | sed -e 's/\r//g'`
WebPort=`echo ${WebPort} | sed -e 's/\r//g'`
WebIPAddress=`echo ${WebIPAddress} | sed -e 's/\r//g'`
GetSectorDataInterval=`echo ${GetSectorDataInterval} | sed -e 's/\r//g'`
GetPlayerDataInterval=`echo ${GetPlayerDataInterval} | sed -e 's/\r//g'`
GetAllianceDataInterval=`echo ${GetAllianceDataInterval} | sed -e 's/\r//g'`
CustomCronjob_1=`echo ${CustomCronjob_1} | sed -e 's/\r//g'`
CustomCronjob_2=`echo ${CustomCronjob_2} | sed -e 's/\r//g'`
CustomCronjob_3=`echo ${CustomCronjob_3} | sed -e 's/\r//g'`
CustomCronjob_4=`echo ${CustomCronjob_4} | sed -e 's/\r//g'`
CustomCronjob_5=`echo ${CustomCronjob_5} | sed -e 's/\r//g'`
KeepDataFiles=`echo ${KeepDataFiles} | sed -e 's/\r//g'`
KeepDataFilesDays=`echo ${KeepDataFilesDays} | sed -e 's/\r//g'`
KeepDataFilesPlayers=`echo ${KeepDataFilesPlayers} | sed -e 's/\r//g'`
KeepDataFilesAlliances=`echo ${KeepDataFilesAlliances} | sed -e 's/\r//g'`
MOTD=`echo ${MOTD} | sed -e 's/\r//g'`
MOTDMessage=`echo ${MOTDMessage} | sed -e 's/\r//g'`
MessageOne=`echo ${MessageOne} | sed -e 's/\r//g'`
MessageTwo=`echo ${MessageTwo} | sed -e 's/\r//g'`
MessageThree=`echo ${MessageThree} | sed -e 's/\r//g'`
MessageFour=`echo ${MessageFour} | sed -e 's/\r//g'`
MessageFive=`echo ${MessageFive} | sed -e 's/\r//g'`
MessageInterval=`echo ${MessageInterval} | sed -e 's/\r//g'`
StopDelay=`echo ${StopDelay} | sed -e 's/\r//g'`
StopWait=`echo ${StopWait} | sed -e 's/\r//g'`
SaveWait=`echo ${SaveWait} | sed -e 's/\r//g'`

#if empty assume .avorion/galaxies
if [ -z $GalaxyDirectory ]; then
  GalaxyDirectoryPath=${SCRIPTPATH}/.avorion/galaxies/
else
  GalaxyDirectoryPath=$GalaxyDirectory/
fi

# Colors
WHITE='\033[1;37m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
NOCOLOR='\033[0m'
# Static - Dont change these
VERSION=1.2.3
APPID=565060
SERVER=${GALAXY}_Server
TMUX_SESSION=${GALAXY}_Tmux
INSTALL_DIR=$SCRIPTPATH/serverfiles
STEAM_DIR=$SCRIPTPATH/steamcmd
Tmux_SendKeys='tmux send-keys -t '${TMUX_SESSION}':0.0'
# Auto Restart
CRONJOB='0,5,10,15,20,25,30,35,40,45,50,55 * * * * '${SCRIPTPATH}'/manager status -o CRON >> '${SCRIPTPATH}'/avorion-manager/logs/$(/bin/date +\%d-\%m-\%Y)_status.log'
CRONDAILYRESTART_NOW='41 11,23 * * * '${SCRIPTPATH}'/manager restart -o CRON -d 15 -b "Restarting Server" >> '${SCRIPTPATH}'/avorion-manager/logs/$(/bin/date +\%d-\%m-\%Y)_status.log'
UpdateServerLog='* * * * * '${SCRIPTPATH}'/manager proc -o CRON'
CRONSECTORDATA='nice -n 10 '${SCRIPTPATH}'/manager get_sector_data -o CRON'
CRONPLAYERDATA='nice -n 15 '${SCRIPTPATH}'/manager get_player_data -o CRON'
CRONALLIANCEDATA='nice -n 15 '${SCRIPTPATH}'/manager get_alliance_data -o CRON'
RequiredCommand=$1
SecondCommand=''
verbose='false'
output=''
broadcast=''
delay=''
force='false'
DisplayDescription=''
DisableCoreExit=''

# skip past the first required command
shift

# skip past the second command
if [[ ! $1 =~ -. ]]; then
  echo 'Skipping'
  SecondCommand=$1
  shift
fi

while getopts 'd:b:o:vhf' flag; do
  case "${flag}" in
    o) output="${OPTARG}" ;;
    b) broadcast="${OPTARG}" ;;
    d) delay="${OPTARG}" ;;
    v) verbose='true' ;;
    h) DisplayDescription='true' ;;
    f) force='true' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

DynamicEcho() {
  # Second Argument used to detect who were echoing too.

  if [ "$output" = "CRON" ]; then
      if [ "$2" != "DONTLOG" ]; then
          echo -e -n $(date +"%F %H-%M-00| "); echo -e '[Manager]: '$1 | sed -r 's/'$(echo -e "\033")'\[[0-9]{1,2}(;([0-9]{1,2})?)?[mK]//g'
      fi
  elif [ "$output" = "PHP" ]; then
    if [ "$2" != "DONTLOG" ]; then
      echo -e $1'\n' | sed -r 's/'$(echo -e "\033")'\[[0-9]{1,2}(;([0-9]{1,2})?)?[mK]//g'
    fi
  else
    if [ "$2" != "DONTLOG" ]; then
      echo -e "${WHITE}[Manager]${NOCOLOR}: $1"
    else
      echo -en "$1"
    fi
  fi
}

if [ ! -z "$broadcast" ]; then
  if [ "$verbose" = true ]; then
    DynamicEcho "${PURPLE}${SERVER}${NOCOLOR} Broadcasting message: $broadcast, will append delay time if \-d is used"
  fi
  if [ -z "$delay" ]; then
    $Tmux_SendKeys '/say [SERVER] '"${broadcast}" C-m
  fi
fi

if [ ! -z "$delay" ]; then
  re='^[0-9]+$'
  if ! [[ $delay =~ $re ]] ; then
     echo "error: Not a number" >&2; exit 1
  fi
  if [ "$verbose" = true ] ; then
    DynamicEcho "${PURPLE}${SERVER}${NOCOLOR} Command suspeneded for $delay minutes"
  fi
  minutes=$delay
  while [ $minutes -gt 0 ]; do
    if [ "$verbose" = true ] ; then
      DynamicEcho "${PURPLE}${SERVER}${NOCOLOR} $minutes minutes until running command."
    fi
    if [ ! -z "$broadcast" ]; then
      if pidof ${SERVER} > /dev/null
  		then
        $Tmux_SendKeys '/say [SERVER] '"${broadcast}"' in '"${minutes}"' minutes.' C-m
      else
        if [ "$verbose" = true ] ; then
          DynamicEcho "${PURPLE}${SERVER}${NOCOLOR} is not running!"
        fi
      fi
    fi
    sleep 60
    minutes=$(($minutes-1))
  done
fi

DeleteCronJobs(){
  crontab -l | grep -v "${SCRIPTPATH}/manager"  | crontab -
  crontab -l | grep -v "${SCRIPTPATH}/avorion-manager"  | crontab -
  crontab -l | grep -v "${CustomCronjob_1}"  | crontab -
  crontab -l | grep -v "${CustomCronjob_2}"  | crontab -
  crontab -l | grep -v "${CustomCronjob_3}"  | crontab -
  crontab -l | grep -v "${CustomCronjob_4}"  | crontab -
  crontab -l | grep -v "${CustomCronjob_5}"  | crontab -
}
CreateCronJobs(){
  if [ "${DAILYRESTART}" = true ]; then
    (crontab -l ; echo "${CRONDAILYRESTART_NOW}") | crontab -
  fi
  if [ ! -z "${MessageOne}" ]; then
    regex='^[0-9]+$'
    if ! [[ $MessageInterval =~ $regex ]] ; then
       MessageInterval=30
    fi
    (crontab -l ; echo "*/${MessageInterval} * * * * ${SCRIPTPATH}/manager broadcast_config_announcments") | crontab -
  fi
  (crontab -l ; echo "${UpdateServerLog}") | crontab -
  (crontab -l ; echo "0 ${GetSectorDataInterval} * * * ${CRONSECTORDATA}") | crontab -
  (crontab -l ; echo "${GetPlayerDataInterval} * * * * ${CRONPLAYERDATA}") | crontab -
  (crontab -l ; echo "${GetAllianceDataInterval} * * * * ${CRONALLIANCEDATA}") | crontab -
  (crontab -l ; echo "${CRONJOB}") | crontab -
  (crontab -l ; echo "${CustomCronjob_1}") | crontab -
  (crontab -l ; echo "${CustomCronjob_2}") | crontab -
  (crontab -l ; echo "${CustomCronjob_3}") | crontab -
  (crontab -l ; echo "${CustomCronjob_4}") | crontab -
  (crontab -l ; echo "${CustomCronjob_5}") | crontab -
}
LogToManagerLog(){
  echo -e -n $(date +"%F %H-%M-%S| ") >> ${SCRIPTPATH}/avorion-manager/logs/$(/bin/date +\%d-\%m-\%Y)_manager.log
  echo -e "[Manager]: $1" >> ${SCRIPTPATH}/avorion-manager/logs/$(/bin/date +\%d-\%m-\%Y)_manager.log

  #Status.log rotation
  find ${SCRIPTPATH}/avorion-manager/logs/*_manager.log -mtime +${LOG_ROTATION} -type f -delete 2> /dev/null
  find ${SCRIPTPATH}/avorion-manager/logs/*_status.log -mtime +${LOG_ROTATION} -type f -delete 2> /dev/null
  find ${SCRIPTPATH}/avorion-manager/logs/*_playerchat.log -mtime +${LOG_ROTATION} -type f -delete 2> /dev/null
}

DisplayHelp(){
  DynamicEcho "available commands:"
  array=($(ls ${SCRIPTPATH}/avorion-manager/manager/*.sh))
  for item in ${array[*]}
  do
      Cleaned=$(echo $item | sed -e 's/\.sh//g' -e 's/.*\///g')
      source <(grep '^COMMAND_DESCRIPTION=' ${SCRIPTPATH}/avorion-manager/manager/${Cleaned}.sh)
      COMMAND_DESCRIPTION=`echo ${COMMAND_DESCRIPTION} | sed -e 's/\r//g'`
      echo -e "    ${GREEN}$Cleaned${NOCOLOR}    --     $COMMAND_DESCRIPTION"
  done
  OptionsArray[0]="${GREEN}o${NOCOLOR}     --     Output, Changes the display output"
  OptionsArray[1]="${GREEN}b${NOCOLOR}     --     Broadcast, Used in conjuction with Delay, will send message each minute of Delay"
  OptionsArray[2]="${GREEN}d${NOCOLOR}     --     Delay, number of minutes to delay a command."
  OptionsArray[3]="${GREEN}v${NOCOLOR}     --     Verbose, will display more output for some commands."
  OptionsArray[4]="${GREEN}h${NOCOLOR}     --     DisplayDescription, shows descrioption of this command."
  OptionsArray[4]="${GREEN}f${NOCOLOR}     --     Force, applies a force option to some commands"
  DynamicEcho "available options:"
  for ix in ${!OptionsArray[*]}
  do
      echo -e "    ${OptionsArray[$ix]}"
  done
}

LoadFile(){
  requested_file="${1}"
  if [ "${2}" ]; then
    SecondCommand="${2}"
  fi

  file_path="${SCRIPTPATH}/avorion-manager/manager/${requested_file}.sh"

  if [ -f "${file_path}" ]; then
    chmod +x "${file_path}"
    LogToManagerLog "Executing: ${requested_file}";
    source "${file_path}"
  else
    file_path="${SCRIPTPATH}/avorion-manager/manager/${requested_file}.php"
    if  [ -f "${file_path}" ]; then

      php -f ${file_path} "${verbose}" "${output}" "${broadcast}" "${delay}" "${force}" "${DisplayDescription}" "${SecondCommand}"
    else
      DisplayHelp;
    fi
  fi
}

LoadFile "${RequiredCommand}" "${SecondCommand}"
