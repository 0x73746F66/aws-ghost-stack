#!/bin/bash -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export NODE_ENV=production
export GHOST_DIR=/var/www/ghost
apt update
apt upgrade -y
apt install -y unzip build-essential libssl-dev git nginx python libyaml-dev awscli
ufw allow 'Nginx Full'
mkdir -p /etc/nginx/cache
curl -sL https://deb.nodesource.com/setup_6.x | bash
apt install -y nodejs
npm install -g ghost-cli@latest pm2
mkdir -p $GHOST_DIR
chown -R ubuntu:ubuntu $GHOST_DIR

mkdir -p ~/.aws
aws_conf=~/.aws/config
echo '' > $aws_conf
cat <<EOF > ${aws_conf}
[default]
region = ${AWS_DEFAULT_REGION}
EOF

curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
python ./awslogs-agent-setup.py --region $AWS_DEFAULT_REGION

awscli_conf=/var/awslogs/etc/awslogs.conf
echo '' > $awscli_conf
cat <<EOF > ${awscli_conf}
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/cloud-init]
datetime_format = %b %d %H:%M:%S
file = /var/log/cloud-init.log
buffer_duration = 5000
log_stream_name = cloud-init-{instance_id}
initial_position = end_of_file
log_group_name = /aws/ec2/ghost

[/var/log/syslog]
datetime_format = %b %d %H:%M:%S
file = /var/log/syslog
buffer_duration = 5000
log_stream_name = syslog-{instance_id}
initial_position = end_of_file
log_group_name = /aws/ec2/ghost

[/var/log/auth]
datetime_format = %b %d %H:%M:%S
file = /var/log/auth.log
buffer_duration = 5000
log_stream_name = auth-{instance_id}
initial_position = end_of_file
log_group_name = /aws/ec2/ghost

[/var/log/apt/history]
datetime_format = %b %d %H:%M:%S
file =  /var/log/apt/history.log
buffer_duration = 5000
log_stream_name = apt-history-{instance_id}
initial_position = end_of_file
log_group_name = /aws/ec2/ghost

[/var/log/nginx/access]
datetime_format = %b %d %H:%M:%S
file = /var/log/nginx/access.log
buffer_duration = 5000
log_stream_name = nginx-access-{instance_id}
initial_position = end_of_file
log_group_name = /aws/ec2/ghost

[/var/log/nginx/error]
datetime_format = %b %d %H:%M:%S
file = /var/log/nginx/error.log
buffer_duration = 5000
log_stream_name = nginx-error-{instance_id}
initial_position = end_of_file
log_group_name = /aws/ec2/ghost
EOF

service awslogs start

export AWS_DEFAULT_REGION=`curl -s http://instance-data/latest/dynamic/instance-identity/document | \
        python -c "import sys, json; print json.load(sys.stdin)['region']"`

db_passwd=`aws ssm get-parameter --name ghost-rds-langton-cloud --with-decryption | python -c "import sys, json; print json.load(sys.stdin)['Parameter']['Value']"`

ghost_conf=$GHOST_DIR/config.production.json
echo '' > $ghost_conf
cat <<EOF > ${ghost_conf}
{
  "url": "https://www.langton.cloud",
  "server": {
    "port": 2368,
    "host": "127.0.0.1"
  },
  "database": {
    "client": "mysql",
    "connection": {
      "host": "ghost-rds.langton.cloud",
      "user": "ghost",
      "password": "${db_passwd}",
      "database": "ghost"
    }
  },
  "mail": {
    "transport": "Direct"
  },
  "logging": {
    "transports": [
      "file",
      "stdout"
    ]
  },
  "storage": {
    "active": "s3",
    "s3": {
      "bucket": "chrisdlangton",
      "pathPrefix": "ghost/",
      "serverSideEncryption": "AES256"
    }
  },
  "process": "systemd",
  "paths": {
    "contentPath": "/var/www/ghost/content"
  }
}
EOF

role_output=`curl -s http://instance-data/latest/meta-data/iam/security-credentials/ec2-ghost-webserver`
key_id=`echo $role_output | \
  python -c "import sys, json; print json.load(sys.stdin)['AccessKeyId']"`
key_secret=`echo $role_output | \
  python -c "import sys, json; print json.load(sys.stdin)['SecretAccessKey']"`

aws_creds=~/.aws/credentials
echo '' > $aws_creds
cat <<EOF > ${aws_creds}
[default]
aws_access_key_id=${key_id}
aws_secret_access_key=${key_secret}
region=${AWS_DEFAULT_REGION}
output=json
EOF

export AWS_ACCESS_KEY_ID=${key_id}
export AWS_SECRET_ACCESS_KEY=${key_secret}

sudo nginx -s reload
sudo ln -sf $GHOST_DIR/system/files/ghost_www-langton-cloud.service /lib/systemd/system/ghost_www-langton-cloud.service
sudo systemctl daemon-reload
