#!/usr/bin/env bash
echo 'Placing Configuration Files'
cp -u -p /opt/osp/installs/nginx-core/nginx.conf /usr/local/nginx/conf/
cp -u -p /opt/osp/installs/nginx-core/mime.types /usr/local/nginx/conf/
cp -u -p /opt/osp/setup/nginx/locations/* /usr/local/nginx/conf/locations
cp -u -p /opt/osp/setup/nginx/upstream/* /usr/local/nginx/conf/upstream

echo 'Setting up Directories'
mkdir -p /var/www && \
  mkdir -p /var/www/live && \
  mkdir -p /var/www/videos && \
  mkdir -p /var/www/live-adapt && \
  mkdir -p /var/www/stream-thumb && \
  mkdir -p /var/www/images  && \
  mkdir -p /var/log/gunicorn && \
  mkdir -p /var/log/osp && \
  chown -R www-data:www-data /var/www && \
  chown -R www-data:www-data /var/log/gunicorn
echo 'Setting up OSP Configuration'

export DB_URL
echo "dbLocation=\"$DB_URL\"" > /opt/osp/conf/config.py
export REDIS_HOST
echo "redisHost=\"$REDIS_HOST\"" >> /opt/osp/conf/config.py
export REDIS_PORT
echo "redisPort=$REDIS_PORT" >> /opt/osp/conf/config.py
export REDIS_PASSWORD
if ! [ -z "$REDIS_PASSWORD" ]
then
      echo "redisPassword=\"$REDIS_PASSWORD\"" >> /opt/osp/conf/config.py
else
      echo "redisPassword=None" >> /opt/osp/conf/config.py
fi

export FLASK_SECRET
echo "secretKey=\"$FLASK_SECRET\"" >> /opt/osp/conf/config.py
export FLASK_SALT
echo "passwordSalt=\"$FLASK_SALT\"" >> /opt/osp/conf/config.py
export OSP_ALLOWREGISTRATION
echo "allowRegistration=$OSP_ALLOWREGISTRATION" >> /opt/osp/conf/config.py
export OSP_REQUIREVERIFICATION
echo "requireEmailRegistration=$OSP_REQUIREVERIFICATION" >> /opt/osp/conf/config.py
export OSP_CORE_UI_DEBUG
echo "debugMode=$OSP_CORE_UI_DEBUG" >> /opt/osp/conf/config.py
export OSP_CORE_LOG_LEVEL
echo "log_level=\"$OSP_CORE_LOG_LEVEL\"" >> /opt/osp/conf/config.py
export EJABBERDADMIN
echo "ejabberdAdmin=\"$EJABBERDADMIN\"" >> /opt/osp/conf/config.py
export EJABBERDPASS
echo "ejabberdPass=\"$EJABBERDPASS\"" >> /opt/osp/conf/config.py
export EJABBERDHOST
echo "ejabberdHost=\"$EJABBERDHOST\"" >> /opt/osp/conf/config.py
export EJABBERDSERVER
echo "ejabberdServer=\"$EJABBERDSERVER\"" >> /opt/osp/conf/config.py
export EJABBERDHTTPBINDFQDN
echo "ejabberdServerHttpBindFQDN=\"$EJABBERDHTTPBINDFQDN\"" >> /opt/osp/conf/config.py

chown -R www-data:www-data /opt/osp/conf/config.py
echo 'Performing DB Migrations'
cd /opt/osp

if [[ ! -d /opt/osp/migrations ]]; then
    python3 manage.py db init
fi
python3 manage.py db migrate
python3 manage.py db upgrade
cd /

echo 'Fixing OSP Permissions Post Migration'
chown -R www-data:www-data /opt/osp

echo 'Starting OSP'
supervisord --nodaemon --configuration /opt/osp/setup/supervisord.conf
