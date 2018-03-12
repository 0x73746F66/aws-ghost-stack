#!/usr/bin/env bash

aws_profile=chris
s3_bucket=chrisdlangton
s3_root=website

touch ./index.html
touch ./error.html

aws --profile $aws_profile s3 cp ./index.html s3://$s3_bucket/$s3_root/index.html \
    --content-type "text/html" \
    --acl public-read \
    --sse

aws --profile $aws_profile s3 cp ./error.html s3://$s3_bucket/$s3_root/error.html \
    --content-type "text/html" \
    --acl public-read \
    --sse

aws --profile $aws_profile s3 website s3://$s3_bucket \
    --index-document index.html \
    --error-document error.html

#aws --profile $aws_profile cloudfront create-distribution \
#    --cli-input-json file://cloudfront.json
aws --profile $aws_profile cloudfront update-distribution \
    --cli-input-json file://cloudfront.json \
    --id E2V6THQ6CH7CI4 \
    --if-match E3GFQ9177TX1PS
# --if-match is from  aws --profile $aws_profile cloudfront get-distribution-config --id E2V6THQ6CH7CI4 | jq ".ETag"

aws --profile $aws_profile route53 change-resource-record-sets \
    --hosted-zone-id Z1P4UG4I6DUNDR --change-batch file://route53.json

