#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2019. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

function usage {
  echo "Usage: $0 -n <namespace>"
}

namespace="cp4i"

while getopts "n:r:" opt; do
  case ${opt} in
    n ) namespace="$OPTARG"
      ;;
    \? ) usage; exit
      ;;
  esac
done

namespace=$(echo $namespace | sed 's/-/_/g')
postgresPod=$(oc get pod -n postgres -l name=postgresql -o jsonpath='{.items[].metadata.name}')

# Check if the database exists
if ! oc exec -n postgres -it $postgresPod \
  -- psql -U ${namespace} -d db_${namespace} -c '\l' ; then
  echo "INFO: Creating Database db_${namespace} , User ${namespace}, "
  oc exec -n postgres -it $postgresPod \
    -- psql << EOF
CREATE DATABASE db_${namespace};
CREATE USER ${namespace} WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE db_${namespace} TO ${namespace};
EOF
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create and setup database" 1>&2
    exit 1
  fi
else
  echo "INFO: Database already exists, skipping this step"
fi

echo "INFO: Create QUOTES table in the database db_${namespace}"
if ! oc exec -n postgres -it $postgresPod \
    -- psql -U ${namespace} -d db_${namespace} -c \
  'CREATE TABLE IF NOT EXISTS QUOTES (
    QuoteID SERIAL PRIMARY KEY NOT NULL,
    Name VARCHAR(100),
    EMail VARCHAR(100),
    Address VARCHAR(100),
    USState VARCHAR(100),
    LicensePlate VARCHAR(100),
    ACMECost INTEGER,
    ACMEDate DATE,
    BernieCost INTEGER,
    BernieDate DATE,
    ChrisCost INTEGER,
    ChrisDate DATE);'; then
  echo "ERROR: Failed to create QUOTES table" 1>&2
  exit 1
fi
