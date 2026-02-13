#!/bin/bash
export PRIIP=`ip route get 1 | awk '{print $7}'`
# export PUBIP=`curl -s ifconfig.me`

export TEST=""
export DAEMON=false
while getopts "ds:t:" arg
do
	case $arg in
	 	s)
            SERVER=$OPTARG
            ;;
		t)
			export TEST=$OPTARG
			;;
		d)
			export DAEMON=true
			;;
	esac
done

./skynet/skynet ./sconfig/config.$SERVER