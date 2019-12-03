#!/bin/bash -x

mkdir -p /root/.local
aws s3 sync --delete --region $region s3://$bucket/$s3key/v2.5.10/ /root/.local/
if [ $? -ne 0 ]
then
	echo "aws s3 sync command failed; exiting."
	exit 1
fi
/bin/parity -d /root/.local --jsonrpc-cors '*' --jsonrpc-interface all --jsonrpc-hosts all
