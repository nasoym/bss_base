#!/usr/bin/env bash
set -ef -o pipefail

while getopts "p:" options; do case $options in
  p) PORT="$OPTARG" ;;
esac; done; shift $(( OPTIND - 1 ))

: ${PORT:="8080"}
: ${SOCAT_OPTIONS:=""} #-vv
: ${SERVICE:="$(dirname $0)/service.sh"}

socat_listen_command="TCP-LISTEN:${PORT},reuseaddr,fork"

socat \
  $SOCAT_OPTIONS \
  $socat_listen_command \
  EXEC:"${SERVICE}"

