#!/usr/bin/env bash

if [[ ! -s /data/.runner ]]; then
  s6-svc -T 10000 /etc/s6-init/forgejo-runner-register
fi

s6-svscan /etc/s6
