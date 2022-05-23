#!/bin/bash

# define path to custom docker environment
DOCKER_ENVVARS=/etc/apache2/docker_envvars

# write variables to DOCKER_ENVVARS
cat << EOF > "$DOCKER_ENVVARS"
export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data
export APACHE_LOG_DIR=/var/log/apache2
export APACHE_LOCK_DIR=/var/lock/apache2
export APACHE_PID_FILE=/var/run/apache2.pid
export APACHE_RUN_DIR=/var/run/apache2
EOF

# source environment variables to get APACHE_PID_FILE
. "$DOCKER_ENVVARS"

# only delete pidfile if APACHE_PID_FILE is defined
if [ -n "$APACHE_PID_FILE" ]; then
   rm -f "$APACHE_PID_FILE"
fi

# start other services


# line copied from /etc/init.d/apache2
ENV="env -i LANG=C PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# use apache2ctl instead of /usr/sbin/apache2
$ENV APACHE_ENVVARS="$DOCKER_ENVVARS" apache2ctl -DFOREGROUND
service apache2 reload

service apache2 restart 

export DISPLAY=:0.0
export PYTHONPATH="/data/pv/pv-5.9/lib64/python3.8/site-packages/"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/pv/pv-5.9/lib64
export PATH=$PATH:/data/pv/pv-5.9/bin
/bin/sh
echo "Starting the wslink launcher"
python /data/pv/pv-5.9/lib64/python3.8/site-packages/wslink/launcher.py /data/pvw/conf/launcher.json &
#vtkpython /data/pv/pv-5.9/share/vtkjsserver/vtkw-server.py --port 1234 --host 0.0.0.0
echo "Starting the wslink launcher"

/bin/sh
