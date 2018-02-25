#!/usr/bin/env bash

aws_profile=chris
s3_bucket=chrisdlangton
s3_root=crypto

aws --profile $aws_profile s3 cp ./index.html s3://$s3_bucket/$s3_root/index.html --content-type "text/html" --acl public-read --sse
aws --profile $aws_profile s3 cp ./error.html s3://$s3_bucket/$s3_root/error.html --content-type "text/html" --acl public-read --sse
aws --profile $aws_profile s3 cp ./stylesheet.css s3://$s3_bucket/$s3_root/stylesheet.css --content-type "text/css" --acl public-read --sse
aws --profile $aws_profile s3 cp ./functions.js s3://$s3_bucket/$s3_root/functions.js --content-type "application/javascript" --acl public-read --sse
aws --profile $aws_profile s3 cp ./template/header.mustache s3://$s3_bucket/$s3_root/template/header.mustache --content-type "application/x-tmpl-mustache" --acl public-read --sse
aws --profile $aws_profile s3 cp ./template/menu.mustache s3://$s3_bucket/$s3_root/template/menu.mustache --content-type "application/x-tmpl-mustache" --acl public-read --sse

