#!/bin/bash -x

mkdir -p /root/datadir
/root/.local/bin/aws s3 sync --delete --region $region s3://$bucket/$s3key/ /root/datadir/
if [ $? -ne 0 ]
then
	echo "aws s3 sync command failed; exiting."
	exit 1
fi
/usr/local/bin/geth --rpc --rpccorsdomain '*' --rpcvhosts '*' --datadir /root/datadir
