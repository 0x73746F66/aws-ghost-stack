#!/usr/bin/env bash

aws_profile=chris
s3_bucket=chrisdlangton
s3_root=crypto

touch ./index.html
touch ./error.html

aws --profile $aws_profile s3 cp ./index.html s3://$s3_bucket/$s3_root/index.html --content-type "text/html" --acl public-read --sse
aws --profile $aws_profile s3 cp ./error.html s3://$s3_bucket/$s3_root/error.html --content-type "text/html" --acl public-read --sse

aws --profile $aws_profile s3 website s3://$s3_bucket --index-document index.html --error-document error.html