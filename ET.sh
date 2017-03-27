#!/bin/sh
ProgVersion="2.1.0"
ProgName="ET"
ProgUrl="https://raw.githubusercontent.com/ActuallyFro/ET/master/ET.sh"

HelpMessage=$(cat <<EOF
External Transmission ($ProgName) v$ProgVersion
=================================
This script phones home;keep working external to your works' network.

Place this script on a 'Dialer' computer. It will "phone home" to your
'SwitchBoard' at home. Connect to the 'SwitchBoard' (or log in), and
ssh to localhost via the reverse connect port configured on the 'Dialer'.

Note: if you DO NOT install ssh keys this script works terribly.
(... you have to type a password EVERYTIME to connect to the 'Dialer')

Options
-------
--attempts | -a - Retry attempts
--sleep | -s - Minutes between retries
--listen-port | -l - The Dialer's SSH Listening port
--flags | -f - SSH flags for connecting to the SwitchBoard
--reverse-port | -r - The port to connect back on via the SwitchBoard
--switch-port | -w - The SwitchBoard's External SSH Port
--hostname-switch | -h - The Hostname or IP of the SwitchBoard
--username-switch | -u - The SwitchBoard's username

--install-cronjob - This will install (or update) a cronjob
--cronrule - This replaces a default callback time of 15 minutes
--cronjob - This option disables retries/sleep settings

Other Options
-------------
--license - print license
--version - print version number
--install - copy this script to /bin/($ProgName)
--update  - update to the most recent GitHub commit
EOF
)

License=$(cat<<EOF
Copyright (c) 2016 Brandon Froberg

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF
)

#Defaults:
ET_Retries="10" ##
ET_SleepMin="2" ##

ET_DialerSSHPort="22" #SSH port that that will be connected back to via the switchboard
ET_DialerSSHFlags="-N -X"

ET_ReverseConnectPort="2222" #"Projected" port of the dialer that is now 'listening' on the switchboard to allow reverse connections

ET_SwitchBoardSSHPort="22" #Port that is listening having remote access for the dialer
ET_SwitchBoardHost="github.com" #IP or FQDN
ET_SwitchBoardUser="actuallyfro" #ssh-enabled Username

ET_PermanentLog="false"

ET_ModeCron="false"
ET_CronInstall="false"
ET_CronRule="*/15 * * * *"

ET_CheckBSD=`uname -a | grep -i "bsd" | wc -l | tr -d " "`

while [ "$#" -gt "0" ]; do
   parsearg="$1" #read in the first argument

   case $parsearg in
   #-----------------------------------#
   ## ET Parse Args
   -a|--attempts)
      ET_Retries="$2"
      shift
   ;;
   -s|--sleep)
      ET_SleepMin="$2"
      shift
   ;;
   -l|--listen-port)
      ET_DialerSSHPort="$2"
      shift
   ;;
   -f|--flags)
      ET_DialerSSHFlags="$2"
      shift
   ;;

   -r|--reverse-port)
      ET_ReverseConnectPort="$2"
      shift
   ;;

   -w|--switch-port)
      ET_SwitchBoardSSHPort="$2"
      shift
   ;;
   -h|--hostname-switch)
      ET_SwitchBoardHost="$2"
      shift
   ;;
   -u|--username-switch)
      ET_SwitchBoardUser="$2"
      shift
   ;;
   --cronjob)
      ET_ModeCron="true"
   ;;
   --debug)
      DEBUG="true"
   ;;
   --install-cronjob)
      ET_CronInstall="true"
   ;;
   --cronrule)
      ET_CronRule="$2"
      shift
   ;;
   --permanent-log)
      ET_PermanentLog="true"
   ;;
   #-----------------------------------#
   --license)
      echo ""
      echo "$License"
      exit
   ;;
   -h|--help)
      echo ""
      echo "$HelpMessage"
      exit
   ;;
   -i|--install)
      echo ""
      echo "Attempting to install $0 to /bin"

      User=`whoami`
      if [ "$User" != "root" ]; then
         echo "[WARNING] Currently NOT root!"
      fi
      cp $0 /bin/$ProgName
      Check=`ls /bin/$ProgName | wc -l | tr -d " "`
      if [ "$Check" = "1" ]; then
         echo "$ProgName installed successfully!"
      fi
      exit
   ;;
   --version)
      echo ""
      echo "Version: $ProgVersion"
      if [ "$ET_CheckBSD" = "1" ];then
         echo "md5 (less last line): "`cat $0 | grep -v "###" | md5 | awk '{print $1}'`
      else
         echo "md5 (less last line): "`cat $0 | grep -v "###" | md5sum | awk '{print $1}'`
      fi
      exit
   ;;
   --crc|--check-script)
      CRCRan=`$0 --version | grep "md5" | tr ":" "\n" | grep -v "md5" | tr -d " "`
      CRCScript=`tail -1 $0 | grep -v "md5sum" | grep -v "cat" | tr ":" "\n" | grep -v "md5" | tr -d " " | grep -v "#"`
      if [ "$CRCRan" = "$CRCScript" ]; then
         echo "$0 is good!"
      else
         echo "The checksums didn't match!"
         echo "1. $CRCRan  (vs.)"
         echo "2. $CRCScript"
      fi
      exit
   ;;
   -u|--update)
   echo ""
   if [ "`which wget`" != "" ]; then
      echo "Grabbing latest GitHub commit..."
      wget $ProgUrl -O /tmp/junk$ProgName
   elif [ "`which curl`" != "" ]; then
      echo "Grabbing latest GitHub commit...with curl...ew"
      curl $ProgUrl > /tmp/junk$ProgName
   else
      echo "... or I cant; Install wget or curl"
   fi

   if [ -f /tmp/junk$ProgName ]; then
      lastVers="$ProgVersion"
      newVers=`cat /tmp/junk$ProgName | grep "Version=" | grep -v "cat" | tr "\"" "\n" | grep "\."`

      lastVersHack=`echo "$lastVers" | tr "." " " | awk '{printf("9%04d%04d%04d",$1,$2,$3)}'`
      newVersHack=`echo "$newVers" | tr "." " " | awk '{printf("9%04d%04d%04d",$1,$2,$3)}'`

      echo ""
      if [ "$lastVersHack" -lt "$newVersHack" ]; then
         echo "Updating $ProgName to $newVers"
         chmod +x /tmp/junk$ProgName

         echo "Checking the CRC..."
         CheckCRC=`/tmp/junk$ProgName --check-script | grep "good" | wc -l | tr -d " "`

         if [ "$CheckCRC" = "1" ]; then
            echo "Installing ..."
            /tmp/junk$ProgName --install
         else
            echo "ERROR! The CRC failed, considering file to be bad!"
            rm /tmp/junk$ProgName
            exit
         fi
         rm /tmp/junk$ProgName
      else
         echo "You are up to date! ($lastVers)"
      fi
   else
      echo "Well ... that happened. (Check your Inet; the new $ProgName couldn't be grabbed!"
   fi
   exit
   ;;
   *)
      #The catch all; Throw warnings or don't...
      echo "[WARNING] Option: $1 -- NOT RECOGNIZED!"
   ;;
   esac

   shift #check next parsed arg
done

###########################################################
# ET Main Program

if [ "$ET_PermanentLog" = "false" ]; then
   LogFile="/tmp/`echo ${0##*/}| sed 's/.sh//g'`.log"
fi

if [ "$ET_PermanentLog" = "true" ]; then
   LogFile="/var/log/`echo ${0##*/}| sed 's/.sh//g'`.log"
   if [ ! -f "$LogFile" ]; then
      echo "[ERROR] No Log file! ($LogFile)"
      sudo touch $LogFile
      sudo chmod 777 $LogFile
      if [ ! -f "$LogFile" ]; then
         echo "[ERROR] DID NOT add the file, rerun as root!"
      else
         echo "[SUCCESS] Added the logfile!"
      fi
      exit
   fi
fi


if [ "$ET_CronInstall" = "true" ]; then
   if [ ! -f /bin/$ProgName ]; then
      echo "[ERROR] $ProgName is NOT installed! CANNOT install a CronJob!"
      exit
   fi
   echo "[$ProgName] Installing the rule: $ET_CronRule /bin/$ProgName --cronjob"
   crontab -l | grep -v "$ProgName" > tmpCron
   echo "$ET_CronRule /bin/$ProgName --cronjob" >> tmpCron
   crontab tmpCron
   rm tmpCron

   checkInstall=`crontab -l | grep "$ET_CronRule" | grep "/bin/$ProgName" | wc -l | tr -d " "`
   if [ "$checkInstall" != "0" ]; then
      echo "[$ProgName][CRON] Successfully Installed the Cronjob!"
   else
      echo "[$ProgName][ERROR] Did NOT Install the Cronjob!"
   fi
   exit
fi

FrozenCheck=`netstat -anpolut | grep "$ET_SwitchBoardSSHPort" | grep "keepalive" | wc -l | tr -d " "`
ServiceCheck=`ps -ef | grep "$ET_ReverseConnectPort" | grep "ssh" | wc -l | tr -d " "`
if [ "$ET_ModeCron" = "true" ]; then
   echo "[$ProgName][CRON] Starting cronjob ($(date +"%Y-%m-%d at %H:%M:%S"))" >> $LogFile
   if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG][CRON] Calling out as a cronjob! ($(date +"%Y-%m-%d at %H:%M:%S"))"; fi
   if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG][CRON]    This is the service check: $ServiceCheck"; fi
   #if [ "$FrozenCheck" = "1" ]; then
#
   #fi
   if [ "$ServiceCheck" = "0" ]; then
      echo "[$ProgName][CRON] Calling: ssh $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags -p $ET_SwitchBoardSSHPort" >> $LogFile
      #NOTE: for 'password-less access create an SSH key; I am lazy and call it 'phone' and place it in bin...
      #if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG][CRON]    Calling: ssh -i /bin/ET_phone -R $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags -p $ET_SwitchBoardSSHPort"; fi
      #ssh -i /bin/ET_phone -o ServerAliveInterval=60 -o ServerAliveCountMax=1 -p $ET_SwitchBoardSSHPort -R $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags
      ssh  -o ServerAliveInterval=60 -o ServerAliveCountMax=1 -p $ET_SwitchBoardSSHPort -R $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags

      if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG][CRON]    DISCONNECTED!"; fi
   else
      if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG][CRON]    Service check PASSED! Not Dialing!"; fi
      echo "[$ProgName][CRON]    Service check PASSED! Not Dialing!" >> $LogFile
   fi

else
   for i in `seq 1 $ET_Retries`;do
      if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG] Starting next dial attempt ($(date +"%Y-%m-%d at %H:%M:%S"))";fi
      echo "[$ProgName] Starting next dial attempt ($(date +"%Y-%m-%d at %H:%M:%S"))" >> $LogFile
      if [ "$DEBUG" ];then  echo "[$ProgName][DEBUG]    Run number: $i/$ET_Retries"; fi
      echo "[$ProgName]    Run number: $i/$ET_Retries" >> $LogFile
      if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG]    Calling: ssh -R $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags -p $ET_SwitchBoardSSHPort | tee $LogFile"; fi
      #echo "[$ProgName]    Calling: ssh -i /bin/ET_phone -o ServerAliveInterval=60 -o ServerAliveCountMax=1 -R $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags -p $ET_SwitchBoardSSHPort" >> $LogFile
      #ssh -i /bin/ET_phone -o ServerAliveInterval=60 -o ServerAliveCountMax=1 -R $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags -p $ET_SwitchBoardSSHPort
      ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=1 -R $ET_ReverseConnectPort:localhost:$ET_DialerSSHPort $ET_SwitchBoardUser@$ET_SwitchBoardHost $ET_DialerSSHFlags -p $ET_SwitchBoardSSHPort

      if [ "$DEBUG" ]; then echo "[$ProgName][DEBUG]    Sleeping for $ET_SleepMin minutes"; fi
      sleep "$ET_SleepMin"m
   done
fi

### Current File MD5 (less this line): 71b67a0161a8245c677317600bc7138f
