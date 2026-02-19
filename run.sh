#!/bin/bash
export PRIIP=`ip route get 1 | awk '{print $7}'`
# export PUBIP=`curl -s ifconfig.me`

export PORT=10010
export TEST=""
export DAEMON=false
while getopts "dp:s:t:" arg
do
	case $arg in
		p)
			export PORT=$OPTARG
			;;
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