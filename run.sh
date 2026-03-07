#!/bin/bash
export PRIIP=`ip route get 1 | awk '{print $7}'`
# export PUBIP=`curl -s ifconfig.me`

export PORT=10010
export TEST="test"
export DAEMON=false
export DEBUG="close"
while getopts "dD:p:s:t:" arg
do
	case $arg in
		D)
			export DEBUG=$OPTARG
			;;
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