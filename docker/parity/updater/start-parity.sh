#!/bin/bash -x

mkdir -p /root/.local
aws s3 sync --delete --region $region s3://$bucket/$s3key/.local/ /root/.local/
if [ $? -ne 0 ]
then
	echo "aws s3 sync command failed; exiting."
	exit 1
fi
/bin/parity --cache-size 2048 --tx-queue-mem-limit 0 --tx-queue-size 40000 --jsonrpc-interface all --jsonrpc-hosts all --no-download --auto-update none --pruning fast --db-compaction ssd --max-peers 10 --min-peers 10 &
sleep 10800
pid=`ps -ef |grep bin/parity|grep -v grep|awk '{print $2}'`
kill $pid
sleep 30
aws s3 sync --delete --region $region /root/.local/ s3://$bucket/$s3key/.local/
