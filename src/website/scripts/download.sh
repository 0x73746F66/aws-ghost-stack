#!/usr/bin/env bash

aws_profile=chris
s3_bucket=chrisdlangton
s3_root=website

aws --profile $aws_profile s3 sync s3://$s3_bucket/$s3_root/ . 