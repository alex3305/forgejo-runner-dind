#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

HOSTNAME=$(hostname)

if [[ -z "${FORGEJO_INSTANCE_URL}" ]]; then
  echo -e "${RED}Required Forgejo Instance URL parameter missing...${NC}"
  exit 255
fi

if [[ -z "${FORGEJO_REGISTRATION_TOKEN}" ]]; then
  echo -e "${RED}Required Forgejo Registration Token parameter missing...${NC}"
  exit 255
fi

CONFIG_ARG=""
if [[ ! -z "${CONFIG_FILE}" ]]; then
  CONFIG_ARG="--config ${CONFIG_FILE}"
fi

EXTRA_ARGS=""
if [[ ! -z "${FORGEJO_RUNNER_LABELS}" ]]; then
  EXTRA_ARGS="${EXTRA_ARGS} --labels ${FORGEJO_RUNNER_LABELS}"
fi

cd /data

REG_TRY=0
REG_SUCCESS=0
REG_ATTEMPTS=${MAX_REG_ATTEMPTS:-5}

while [[ $REG_SUCCESS -eq 0 ]] && [[ $REG_TRY -lt $REG_ATTEMPTS ]]; do
  forgejo-runner register \
      --instance "${FORGEJO_INSTANCE_URL}" \
      --token    "${FORGEJO_REGISTRATION_TOKEN}" \
      --name     "${FORGEJO_RUNNER_NAME:-$HOSTNAME}" \
      ${CONFIG_ARG} ${EXTRA_ARGS} --no-interactive 2>&1 | tee /tmp/reg.log

  cat /tmp/reg.log | grep 'Runner registered successfully' > /dev/null

  if [[ $? -eq 0 ]]; then
    REG_SUCCESS=1
    break
  else
    REG_TRY=$((REG_TRY + 1))
    echo -e "${ORANGE}Retrying Forgejo Runner Registration to $FORGEJO_INSTANCE_URL in 5 seconds... Registration attempt $REG_TRY/$REG_ATTEMPTS${NC}"
    sleep 5
  fi
done

if [[ $REG_SUCCESS -eq 1 ]]; then
  echo -e "${GREEN}Forgejo Runner Registration completed successfully!${NC}"
  exit 0
else
  echo -e "${RED}Could not register Forgejo Runner to $FORGEJO_INSTANCE_URL after $REG_ATTEMPTS attempts.${NC}"
  exit 1
fi
