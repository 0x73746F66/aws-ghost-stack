#!/usr/bin/env bash
GHOST_DIR=/var/www/ghost
sudo apt update
sudo apt upgrade -y
sudo apt install -y unzip build-essential libssl-dev git nginx python libyaml-dev python-pip
pip install --upgrade pip
pip install awscli
sudo ln -s /home/ubuntu/.local/bin/aws /usr/bin/aws
sudo ufw allow 'Nginx Full'
sudo mkdir -p /etc/nginx/cache
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash
sudo apt install -y nodejs
sudo npm install -g ghost-cli@latest pm2
sudo mkdir -p $GHOST_DIR
sudo chown -R ubuntu:ubuntu $GHOST_DIR
cd $GHOST_DIR
ghost install
sudo chown -R ubuntu:ubuntu $GHOST_DIR
# Choose to continue without local database/s
# Allow setup of Nginx, skip SSL and Systemd
# Do not start ghost yet

# add the following to /etc/nginx/nginx.conf
        # cache
#        proxy_cache_path /etc/nginx/cache levels=1:2 keys_zone=cache:60m max_size=300m inactive=24h;
#        proxy_cache_key "$scheme$request_method$host$request_uri";
#        proxy_cache_methods GET HEAD;
#        gzip_disable "msie6";

sudo ln -sf $GHOST_DIR/system/files/www.langton.cloud.conf /etc/nginx/sites-available/www.langton.cloud.conf
sudo ln -sf /etc/nginx/sites-available/www.langton.cloud.conf /etc/nginx/sites-enabled/www.langton.cloud.conf
sudo nginx -s reload
sudo ln -sf $GHOST_DIR/system/files/ghost_www-langton-cloud.service /lib/systemd/system/ghost_www-langton-cloud.service
sudo systemctl daemon-reload

sudo /usr/lib/node_modules/ghost-cli/node_modules/.bin/knex-migrator-migrate --init --mgpath $GHOST_DIR/current
# s3 images
export GHOST_VERSION=`node -p -e "require('$GHOST_DIR/current/package.json').version"`
cd $GHOST_DIR/versions/$GHOST_VERSION/
# https://github.com/chrisdlangton/ghost-storage-adapter-s3
# copy the built index.js to;
# $GHOST_DIR/versions/$GHOST_VERSION/core/server/adapters/storage/s3/index.js

# an example extracting information from instance meta data, including creds
export AWS_DEFAULT_REGION=`curl -s http://instance-data/latest/dynamic/instance-identity/document | \
        python -c "import sys, json; print json.load(sys.stdin)['region']"`
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
sudo python ./awslogs-agent-setup.py --region $AWS_DEFAULT_REGION
sudo service awslogs start
export NODE_ENV=production
# ghost-storage-adapter-s3 does not read creds from the EC2 IAM role
export AWS_ACCESS_KEY_ID="<change me>"
export AWS_SECRET_ACCESS_KEY="<change me>"

# put diff of config.production.json in $GHOST_DIR
sudo chown -R ubuntu:ubuntu $GHOST_DIR
# auto start ghost with pm2 via /etc/rc.local
cd $GHOST_DIR
pm2 startup ubuntu -u ubuntu --hp $GHOST_DIR
pm2 start current/index.js --name ghost
# save & exit rc.local
