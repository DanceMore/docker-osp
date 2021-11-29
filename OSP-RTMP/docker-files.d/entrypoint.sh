#!/usr/bin/env bash
echo 'Placing Configuration Files'
cp -u /repo/flask-nginx-rtmp-manager/installs/osp-rtmp/setup/nginx/servers/* /usr/local/nginx/conf/servers
cp -p /repo/flask-nginx-rtmp-manager/installs/osp-rtmp/setup/nginx/services/* /usr/local/nginx/conf/services

echo 'Setting up Directories'
  mkdir -p /var/www && \
  mkdir -p /var/www/live && \
  mkdir -p /var/www/videos && \
  mkdir -p /var/www/live-adapt && \
  mkdir -p /var/www/stream-thumb && \
  mkdir -p /var/log/gunicorn && \
  mkdir -p /var/log/osp && \
  chown -R www-data:www-data /var/www && \
  chown -R www-data:www-data /var/log/gunicorn && \
  chown -R www-data:www-data /var/log/osp
echo 'Setting up OSP Configuration'

export OSP_RTMP_UI_DEBUG
echo "debugMode=$OSP_RTMP_UI_DEBUG" >> /opt/osp-rtmp/conf/config.py
export OSP_RTMP_LOG_LEVEL
echo "log_level=\"$OSP_RTMP_LOG_LEVEL\"" >> /opt/osp-rtmp/conf/config.py
export OSPCOREAPI
echo "ospCoreAPI=\"$OSPCOREAPI\"" >> /opt/osp-rtmp/conf/config.py
export FLASK_SECRET
echo "secretKey=\"$FLASK_SECRET\"" >> /opt/osp-rtmp/conf/config.py

chown -R www-data:www-data /opt/osp-rtmp/conf/config.py

echo 'Fixing OSP Permissions Post Migration'
chown -R www-data:www-data /opt/osp-rtmp

echo 'Starting OSP'
supervisord --nodaemon --configuration /opt/osp-rtmp/supervisord.conf
