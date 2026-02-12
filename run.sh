export TEST=$2
export PRIIP=`ip route get 1 | awk '{print $7}'`
export PUBIP=`curl -s ifconfig.me`
./skynet/skynet ./sconfig/config.$1