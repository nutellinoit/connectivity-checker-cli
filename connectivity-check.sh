#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
YAML_FILE=checks.yaml
ENVIRONMENT=$1

if [ "$2" == "" ]; then
  YAML_FILE=checks.yaml
else
  YAML_FILE=$2
fi

if [ -z "${ENVIRONMENT}" ]; then
    echo "Usage ./connectivity-check.sh [environment] <configfile.yaml>"
    exit 1
fi

set -eu

function ncCheck() {


  EXITCODE=0
  if [ "$3" == "UDP" ]; then
    timeout 2 nc -zu -w 1 $1 $2 > /dev/null 2>&1 || EXITCODE=$?

    if [ "$EXITCODE" -eq "0" ]; then
      echo -e "${GREEN}[SUCCESS]${NC} - $1 is reachable on port $2 with protocol UDP"
    else

      echo -e "${RED}[FAIL]${NC} - $1 is not reachable on port $2 with protocol UDP"
    fi
  else
    timeout 2 nc -z -w 1 $1 $2 > /dev/null 2>&1 || EXITCODE=$?

    if [ "$EXITCODE" -eq "0" ]; then
      echo -e "${GREEN}[SUCCESS]${NC} - $1 is reachable on port $2 with protocol TCP"
    else
      echo -e "${RED}[FAIL]${NC} - $1 is not reachable on port $2 with protocol TCP"

    fi
  fi


}

ENDPOINTS=$(yq e '.common.endpoints | length' ${YAML_FILE})

for (( c=0; c<${ENDPOINTS}; c++ ))
do
  # Test endpoint

  ADDRESS=$(yq e '.common.endpoints['"${c}"'].address' ${YAML_FILE})
  PORT=$(yq e '.common.endpoints['"${c}"'].port' ${YAML_FILE})
  PROTOCOL=$(yq e '.common.endpoints['"${c}"'].protocol' ${YAML_FILE})

  ncCheck ${ADDRESS} ${PORT} ${PROTOCOL}

done

ENDPOINTS=$(yq e '.environments.'${ENVIRONMENT}'.endpoints | length' ${YAML_FILE})

for (( c=0; c<${ENDPOINTS}; c++ ))
do
  # Test endpoint

  ADDRESS=$(yq e '.environments.'${ENVIRONMENT}'.endpoints['"${c}"'].address' ${YAML_FILE})
  PORT=$(yq e '.environments.'${ENVIRONMENT}'.endpoints['"${c}"'].port' ${YAML_FILE})
  PROTOCOL=$(yq e '.environments.'${ENVIRONMENT}'.endpoints['"${c}"'].protocol' ${YAML_FILE})

  ncCheck ${ADDRESS} ${PORT} ${PROTOCOL}

done