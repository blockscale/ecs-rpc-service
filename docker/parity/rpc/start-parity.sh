#!/bin/bash

mkdir -p /root/.local
aws s3 sync --delete --region $region s3://$bucket/$s3key/.local/ /root/.local/
if [ $? -ne 0 ]
then
	echo "aws s3 sync command failed; exiting."
	exit 1
fi
/bin/parity --cache-size 2048 --tx-queue-mem-limit 0 --tx-queue-size 40000 --jsonrpc-cors '*' --jsonrpc-interface all --jsonrpc-hosts all --no-download --auto-update none --pruning fast --db-compaction ssd --max-peers 10 --min-peers 10
