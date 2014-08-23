#!/bin/sh

##
# netstat2xml.sh 
#
# Author: Guilherme G. Martins - gmartins at cc.gatech.edu
##

#
ROOTNODE_NAME=netstat

if [ "$#" -lt 2 ]; then
 echo "usage: ${0##*/} <init|delta> <path/to/tmpfile> [param1=val, param2=val2, ... ]"
 exit 1
fi

NETSTAT_KEY=$2.key.txt
NETSTAT_VAL1=$2.val1.txt
NETSTAT_VAL2=$2.val2.txt
NETSTAT_VAL=$2.val.txt

## init key and val
if [ $1 = "init" ]; then
  rm -f $2.*
  sed -n 1p /proc/net/netstat | sed "s/ /\n/g" > $NETSTAT_KEY
  sed -n 7p /proc/net/snmp | sed "s/ /\n/g" >> $NETSTAT_KEY 
  echo "deltaTime" >> $NETSTAT_KEY
  sed -i "/TcpExt:/d" $NETSTAT_KEY
  sed -i "/Tcp:/d" $NETSTAT_KEY

  sed -n 2p /proc/net/netstat | sed "s/ /\n/g" > $NETSTAT_VAL1
  sed -n 8p /proc/net/snmp | sed "s/ /\n/g" >> $NETSTAT_VAL1
  date +%s >> $NETSTAT_VAL1
  sed -i "/TcpExt:/d" $NETSTAT_VAL1
  sed -i "/Tcp:/d" $NETSTAT_VAL1
else 
  ## delta
  if [ -f $NETSTAT_VAL1 ]; then
    sed -n 2p /proc/net/netstat | sed "s/ /\n/g" > $NETSTAT_VAL2
    sed -n 8p /proc/net/snmp | sed "s/ /\n/g" >> $NETSTAT_VAL2
    date +%s >> $NETSTAT_VAL2
    sed -i "/TcpExt:/d" $NETSTAT_VAL2
    sed -i "/Tcp:/d" $NETSTAT_VAL2
  else 
    ## init anyway, silently exit
    sed -n 2p /proc/net/netstat | sed "s/ /\n/g" > $NETSTAT_VAL1
    sed -n 8p /proc/net/snmp | sed "s/ /\n/g" >> $NETSTAT_VAL1
    date +%s >> $NETSTAT_VAL1
    sed -i "/TcpExt:/d" $NETSTAT_VAL1
    sed -i "/Tcp:/d" $NETSTAT_VAL1
    exit 1
  fi

fi

if [ -f $NETSTAT_VAL2 ] 
then
  dd of=$NETSTAT_VAL count=0 2>/dev/null

  while read -r l1 && read -r l2 <&3;
  do
    #printf "$l1 $l2\n"
    line=`expr $l2 - $l1`
    echo $line >> $NETSTAT_VAL
  done < $NETSTAT_VAL1 3<$NETSTAT_VAL2

  printf "<$ROOTNODE_NAME "
  while read -r l1 && read -r l2 <&3;
  do 
     printf " $l1=\"$l2\""
     echo $line >> $NETSTAT_VAL
  done < $NETSTAT_KEY 3<$NETSTAT_VAL

  for args in "$@"
  do
    [ "$args" = "$1" ] && continue
    [ "$args" = "$2" ] && continue
    printf " $args"
  done

  printf " />\n"
  rm -f $NETSTAT_VAL2 $NETSTAT_VAL
else
  if [ $1 = "init" ];
  then
    printf "<$ROOTNODE_NAME "
    while read -r l1 && read -r l2 <&3;
    do
       printf " $l1=\"$l2\""
    echo $line >> $NETSTAT_VAL
    done < $NETSTAT_KEY 3<$NETSTAT_VAL1
    printf " />\n"
    fi
fi


