#!/usr/bin/env bash

aws_profile=chris
s3_bucket=chrisdlangton
s3_root=website

aws --profile $aws_profile s3 sync . s3://$s3_bucket/$s3_root/ --exclude="*" --include="*.html" --content-type "text/html" --acl public-read --sse
aws --profile $aws_profile s3 sync . s3://$s3_bucket/$s3_root/ --exclude="*" --include="*.css" --content-type "text/css" --acl public-read --sse
aws --profile $aws_profile s3 sync . s3://$s3_bucket/$s3_root/ --exclude="*" --include="*.json" --exclude="aws/*" --content-type "text/json" --acl public-read --sse
aws --profile $aws_profile s3 sync . s3://$s3_bucket/$s3_root/ --exclude="*" --include="*.js" --content-type "application/javascript" --acl public-read --sse
aws --profile $aws_profile s3 sync . s3://$s3_bucket/$s3_root/ --exclude="*" --include="*.mustache" --content-type "application/x-tmpl-mustache" --acl public-read --sse
