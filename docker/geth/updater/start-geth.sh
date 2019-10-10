#!/bin/bash -x

mkdir -p /root/datadir
/root/.local/bin/aws s3 sync --delete --region $region s3://$bucket/$s3key/ /root/datadir/
if [ $? -ne 0 ]
then
	echo "aws s3 sync command failed; exiting."
	exit 1
fi
/usr/local/bin/geth --rpc --rpccorsdomain '*' --rpcvhosts '*' --datadir /root/datadir
sleep 10800
pid=`ps -ef |grep bin/parity|grep -v grep|awk '{print $2}'`
kill $pid
sleep 30
aws s3 sync --delete --region $region /root/datadir/ s3://$bucket/$s3key/
