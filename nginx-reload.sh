#!/bin/bash

{
  echo "Starting nginx"
  nginx "$@" && exit 1
} &

nginx_pid=$!

watches=${WATCH_PATHS:-"/etc/nginx/nginx.conf"}

echo "Setting up watches for ${watches[@]}"
echo

{
  calc_hash() {
    for i in `find "$1" -type f | sort`; do echo $i; ls -l $i; cat $i; done | sha512sum
  }

  START=`calc_hash ${watches[@]}`

  echo $nginx_pid
  while true; do
    NOW=`calc_hash ${watches[@]}`

    if [[ "$START" != "$NOW" ]]; then
      START=$NOW
      echo; echo
      echo "At `date`, config file update detected"

      nginx -t
      if [ $? -ne 0 ]; then
        echo "ERROR: New configuration is invalid!!"
      else
        echo "New configuration is valid, reloading nginx"
        nginx -s reload
      fi

      echo; echo
    fi

    sleep 10s
  done
  echo "poor man's inotifywait failed, killing nginx"

  kill -TERM $nginx_pid
} &

wait $nginx_pid || exit 1
