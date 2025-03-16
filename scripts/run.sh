#!/usr/bin/env bash

if [[ ! -d /data ]]; then
  mkdir -p /data
fi

cd /data

CONFIG_ARG=""
if [[ ! -z "${CONFIG_FILE}" ]]; then
  CONFIG_ARG="--config ${CONFIG_FILE}"
fi

EXTRA_ARGS=""
if [[ ! -z "${FORGEJO_RUNNER_LABELS}" ]]; then
  EXTRA_ARGS="${EXTRA_ARGS} --labels ${FORGEJO_RUNNER_LABELS}"
fi

# Use the same ENV variable names as https://github.com/vegardit/docker-gitea-act-runner
if [[ ! -s .runner ]]; then
  try=$((try + 1))
  success=0

  # The point of this loop is to make it simple, when running both forgejo-runner and gitea in docker,
  # for the forgejo-runner to wait a moment for Forgejo to become available before erroring out.  Within
  # the context of a single docker-compose, something similar could be done via health checks, but
  # this is more flexible.
  while [[ $success -eq 0 ]] && [[ $try -lt ${MAX_REG_ATTEMPTS:-10} ]]; do
    forgejo-runner register \
      --instance "${FORGEJO_INSTANCE_URL}" \
      --token    "${FORGEJO_REGISTRATION_TOKEN}" \
      --name     "${FORGEJO_RUNNER_NAME:-`hostname`}" \
      ${CONFIG_ARG} ${EXTRA_ARGS} --no-interactive 2>&1 | tee /tmp/reg.log

    cat /tmp/reg.log | grep 'Runner registered successfully' > /dev/null
    if [[ $? -eq 0 ]]; then
      echo "SUCCESS"
      success=1
    else
      echo "Waiting to retry ..."
      sleep 5
    fi
  done
fi

# Prevent reading the token from the forgejo-runner process
unset FORGEJO_REGISTRATION_TOKEN

forgejo-runner daemon ${CONFIG_ARG}
