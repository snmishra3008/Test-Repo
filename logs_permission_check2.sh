#!/bin/bash
#***************************************************************************************************************************
#                                               logs_permission_check.sh Script
#***************************************************************************************************************************
# Inventory Check/modify Logs permission and unkonwn users
# Author : Shiv Narayan Mishra
# Version : 1.2

set -u; # No undefined variables use is allowed anymore.

#*******************************************************************************
#                             Error codes definition
#*******************************************************************************

typeset -ri ERROR_PARAM=42; # Command line parameter(s) error.
typeset -ri ERROR_NONLinux=1;  #  The OS is not Linux
typeset -ri ERROR_NONPlaton=4;  #  The Image is not Platon

#*******************************************************************************
#                             Variables definition
#*******************************************************************************
typeset HOSTNAME=`hostname`
typeset OUTPUT_DIR=""
typeset OUTPUT_FILE=""
typeset OSname=""
typeset temposname=""
typeset OSRelease=""
typeset OSImage=""

# The output directory
typeset OUTPUT_DIR; # The path of the output directory.

# The output filename
typeset -r OUTPUT_FILE="incorrect_logs_perm";
typeset DISCOVERY_RESULT;

# Return code
typeset -i RC=0;

#*******************************************************************************
#                                   Init
#*******************************************************************************
# Name of the OS
temposname=`uname -s`

if [ "$temposname" = "Linux" ]
then
  OSname="Linux";
else
echo "[ERROR] NON LINUX Operating system..."
exit ${ERROR_NONLinux};
fi

#Run only for RHEL 7.3
cat /etc/redhat-release |grep '7.3'
if [ "$?" -eq 0 ]
then 
	OSRelease="RHEL7.3"
else
echo " [ERROR] NOT RHEL 7.3"
exit ${ERROR_NONLinux};
fi

#Checking Platon image
echo "Check If OS image is a Platon Image"
ls -ltr /etc/signatures/
if [ "$?" -eq 0 ]
then 
	OSImage="Platon Image"
else
echo " [ERROR] NON Platon Image.."
exit ${ERROR_NONPlaton};
fi

# If the first argument is missing or if it is the empty string, we exit.
if [ $# -lt 1 -o -z "${1:-}" ]; then
  echo "[ERROR] Missing OUTPUT_DIR parameter...";
  echo "Usage : $0 <OUTPUT_DIR>";
  exit ${ERROR_PARAM};
fi
OUTPUT_DIR=$1;

DISCOVERY_RESULT="${OUTPUT_DIR}/${OUTPUT_FILE}";
# Creating the output directory (if needed) and the empty output file
[ ! -d "$OUTPUT_DIR" ] && mkdir "$OUTPUT_DIR";

[ -f "${DISCOVERY_RESULT}" ] && rm -f "${DISCOVERY_RESULT}";
touch "${DISCOVERY_RESULT}";

#*******************************************************************************
#                                   MAIN
#*******************************************************************************
#checking users games, tape, video and audio. If user exists it will print the current login shell as mentioned in /etc/passwd and modify it to /sbin/nologin
for i in games tape video audio
do
echo $i
id $i
if [ "$?" -eq 0 ] ;
then
echo "Checking Users shell for user" " $i "
g1=`(grep $i /etc/passwd |awk -F : '{print $NF}')`
usermod --shell /sbin/nologin $i
v_user+=`(echo "$i" ",")`
else
v_nouser+=`(echo "$i " ",")`
fi
done

#first Print all files user logs directory and than modify permission as requested.

a1=`find /usr/nsh/NSH/log/ -type f -exec stat  -c "%a %n" {} \;`
if [ "$a1" != 0 ] ;
then
find /usr/nsh/NSH/log/ -type f -exec chmod 644 {} \;
echo "files /usr/nsh/NSH/log/ permission changed to 644"
fi

b1=`find /opt/operating/log/ -type f -exec stat  -c "%a %n" {} \;`
if [ "$b1" !=  0 ] ;
then
find /opt/operating/log/ -type f -exec chmod 644 {} \;
echo "files under /opt/operating/log/ permission changed to 644"
fi

c1=`find /var/log/syslog/ -type f -name secure.log  -exec stat  -c "%a %n" {} \;`
if [ "$c1" !=  0 ] ;
then
find /var/log/syslog/ -type f -name 'secure.log' -exec chmod 600 {} \;
echo "files under /var/log/syslog/ permission changed to 644"
fi

d1=`find /usr/nsh/NSH/ -type d -name log -exec stat  -c "%a %n" {} \;`
if [ "$d1" !=  0 ] ;
then
find /usr/nsh/NSH/ -type d -name log -exec chmod 755 {} \;
echo "directory permission under /usr/nsh/NSH/ changed to 755"
fi

e1=`find /opt/operating/ -type d -name log -exec stat  -c "%a %n" {} \;`
if [ "$e1" !=  0 ] ;
then
find /opt/operating/ -type d -name log -exec chmod 755 {} \;
e2=$(echo -n `find /opt/operating/ -type d -exec stat  -c "%a %n" {} \;`)
echo "directory permission under /opt/operating/ changed to 755"
fi

f1=`find /var/opt/ -type d -name log -exec stat  -c "%a %n" {} \;`
if [ "$f1" !=  0 ] ;
then
find /var/opt/ -type d -name log -exec chmod 755 {} \;
f2=$(echo -n `find /var/opt/ -type d -exec stat  -c "%a %n" {} \;`)
echo "directory permission under /var/opt/ changed to 755"
fi

echo $HOSTNAME " ; " "Users-:"$v_user '"Shell changed to /sbin/nologin"' ";" " Users-:"$v_nouser '"Users not exists"'  " ; " $a1 $b1 $c1 " ; File permissions are 644 " " ; " $d1 $e1 $f1 " ; Dir permissions are 755"  >> $OUTPUT_DIR/$OUTPUT_FILE
exit $RC