#!/bin/bash -x

mkdir -p /root/.local
aws s3 sync --delete --region $region s3://$bucket/$s3key/v2.5.10/ /root/.local/
/bin/parity $*
