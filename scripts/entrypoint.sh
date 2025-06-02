#!/usr/bin/env bash

if [[ ! -s /data/.runner ]]; then
  timeout 60 /register.sh
fi

if [[ $? -ne 0 ]]; then
  echo "Cannot start Forgejo Runner due to previous errors."
  exit 1
fi

s6-svscan /etc/s6
