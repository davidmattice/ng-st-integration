#!/bin/bash
###############################################################################
#
# Bash script to update Stmartthing Presence status for devices wirelessly
# connected to a Netgrear router.
#
# Use -h to see options for running the script
#
###############################################################################
#
# Parse program name
#
prog=${0##*/}
dir=${0%/*}
if [ "${dir}" = "${0}" ]; then
   dir="."
fi

#
# Setup variables
# Default is that everything happens in the current directory
#
prgname=${prog%.*}               # Base name of the program
statedir=${dir}                  # Direstory to store state of devices in
logdir=${dir}                    # Directory to write log too
logfile=${dir}/${prgname}.log    # File to write logs too
devfile=${dir}/${prgname}.lst    # File with the list of devices in it
pswdfile=${dir}/${prgname}.pswd  # File the password to the router is stored in
sleeptime=45                     # It takes approximatly 45 seconds to run
awaycnt=4                        # Device must be missed X times to be AWAY
verbose=0                        # 0=No output, 1=Time stamped output
sturl="https://graph-na04-useast2.api.smartthings.com/api/smartapps/installations"

#
# Parse command line options here
#
OPTIND=1
while getopts ":hv:s:a:l:d:p:S:" opt
do
   case "$opt" in
      v) if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
            echo "Error: Option -v takes an integer argument"
            exit 1
         fi
         verbose=$OPTARG
         ;;
      S) if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
            echo "Error: Option -s takes an integer argument"
            exit 1
         fi
         sleeptime=$OPTARG
         ;;
      a) if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
            echo "Error: Option -a takes an integer argument"
            exit 1
         fi
         awaycnt=$OPTARG
         ;;
      s) if [ ! -w ${OPTARG} -a ! -d ${OPTARG} ]; then
            echo "Error: Option -s argument must we a writeable directory"
            exit 1
         fi
         statedir=$OPTARG
         ;;
      l) logdir=${OPTARG%/*}
         if [ "${logdir}" = "${OPTARG}" ]; then
            logdir="."
         fi
         if [ ! -w ${OPTARG} -a ! -w ${logdir} ]; then
            echo "Error: Option -l argument must we a writeable file"
            exit 1
         fi
         logfile=$OPTARG
         ;;
      d) if [ ! -r ${OPTARG} ]; then
            echo "Error: Option -d argument must we a readable file"
            exit 1
         fi
         devfile=$OPTARG
         ;;
      p) if [ ! -r ${OPTARG} ]; then
            echo "Error: Option -p argument must we a readable file"
            exit 1
         fi
         pswdfile=$OPTARG
         ;;
      h) echo "${prog}: [-h | -v level | -s time | -a cnt | -l logfile | -p passwdfile | -d devicefile ]"
         echo "     -h  This message"
         echo "     -v  Verbose loging (default: ${verbose})"
         echo "     -S  Sleeptime between calls (default: ${sleeptime})"
         echo "     -a  Number of consecutive misses to declare as away (default: ${awaycnt})"
         echo "     -l  Logfile name for messages (default: ${logfile})"
         echo "     -s  Directory to save statefiles to (default: ${statedir})"
         echo "     -d  Devile list file to be checked on each pass (default: ${devfile})"
         echo "     -p  File with the password for the router (default: ${pswdfile})"
         exit 0
         ;;
      :) echo "Options Error"
         exit 1
         ;;
   esac
done

#
# Read the password from the password file
#
if [ ! -r ${pswdfile} ]; then
   echo "Error: Can't read ${pswdfile}"
   exit 2
fi
passwd=`grep -v '^#' ${pswdfile}`
if [ -z "${passwd}" ]; then
   echo "Error: Password can't be a blank value"
   exit 2
fi

#
# Read the list of devices to check for
# This is a text file with one device per line
#    name,mac,appid,token
#
if [ ! -r ${devfile} ]; then
   echo "Error: Can't read ${devfile}"
   exit 3
fi
devlst=`grep -v "^#" ${devfile}`
devcnt=`printf '%s\n' "${devlst}" | wc -l`
if [ -z "${devlst}" ]; then
   echo "Error: Device list can't be empty"
   exit 3
fi

#
# Log starting message
#
if [ ! -w ${logfile} -a ! -w ${logdir} ]; then
   echo "Error: Can't write to ${logfile}"
   exit 4
fi
if [ ${verbose} -ge 1 ]; then
   dtstmp=`date +%Y%m%dT%H%M%S`
   echo "${dtstmp} starting" >>${logfile}
fi

#
# Initialize the array to track the consecutive count of miises
#
awayarr=()
while [ ${#awayarr[@]} -lt ${devcnt} ]
do
   awayarr+=( 0 )
done

###############################################################################
#    MAIN
###############################################################################
#
# Run forever checking for presence of devices on the Wifi
#
while :
do
   tmstmp=`date +%H%M%S`
   dtstmp=`date +%Y%m%dT%H%M%S`
   msg=""
   devidx=0

   output=`python -m pynetgear ${passwd} | grep -v "link_rate=None"`

   while IFS=',' read -r name mac app token junk
   do
      found=`echo ${output} | grep -c -i "${mac}.*wireless"`
      flagfile=${statedir}/${prgname}.${name}
      if [ ${found} -ne 0 ]; then
         awayarr[${devidx}]=0
         if [ ! -f ${flagfile} ]; then
            touch ${flagfile}
            if [ ${verbose} -ge 2 ]; then
               msg="${msg}, ${name} home"
            fi
            curl -v "${sturl}/${app}/Phone/home?access_token=${token}" -k 2>&1 | grep "HTTP/1.1 200 OK" >/dev/null
            if [ $? -ne 0 ]; then
               curlout=`curl -v "${sturl}/${app}/Phone/home?access_token=${token}" -k 2>&1 | grep "HTTP/1.1 "`
               echo "${dtstmp} ${name} ${sturl}/${app}/Phone/home?access_token=${token} ${curlout}" >>${logfile}
            fi
         fi
      else
         if [ -f ${flagfile} ]; then
            if [ ${awayarr[${devidx}]} -ge ${awaycnt} ]; then
               rm -f ${flagfile}
               if [ ${verbose} -ge 2 ]; then
                  msg="${msg}, ${name} away"
               fi
               curl -v "${sturl}/${app}/Phone/away?access_token=${token}" -k 2>&1 | grep "HTTP/1.1 200 OK" >/dev/null
               if [ $? -ne 0 ]; then
                  curlout=`curl -v "${sturl}/${app}/Phone/home?access_token=${token}" -k 2>&1 | grep "HTTP/1.1 "`
                  echo "${dtstmp} ${name} ${sturl}/${app}/Phone/home?access_token=${token} ${curlout}" >>${logfile}
               fi
            else
               (( awayarr[${devidx}] = awayarr[${devidx}] + 1 ))
               if [ ${verbose} -ge 3 ]; then
                  msg="${msg}, ${name} ${awayarr[${devidx}]} of ${awaycnt}"
               fi
            fi
         fi
      fi
      (( devidx = devidx + 1 ))

   done < <(printf '%s\n' "${devlst}")
   if [ ${verbose} -ge 4 -o ! -z "${msg}" ]; then
      echo "${dtstmp} checked${msg}" >>${logfile}
   fi
   if [ ${sleeptime} -eq 0 ]; then
      exit 1
   fi
   sleep ${sleeptime}
done

