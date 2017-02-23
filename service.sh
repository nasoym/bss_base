#!/usr/bin/env bash

set -f -o pipefail

source lib/logger
source lib/http_helpers
source lib/parse_request
source lib/find_handler_file
source lib/jwt_verify

: ${ROUTES_PATH:="$(dirname $0)/handlers"}
: ${DEFAULT_ROUTE_HANDLER:="${ROUTES_PATH}/default"}
: ${AUTHENTICATE:="1"}
: ${VERBOSE_LOGGING:="0"}

parse_request
log "request: ${SOCAT_PEERADDR}:${SOCAT_PEERPORT} ${request_method} ${request_uri}"

if [[ "$AUTHENTICATE" = 1 ]];then
  if [[ -z "$request_header_authorization" ]];then
    authorization_token="$( echo "$request_header_cookie" \
      | sed -e 's/; */\n/g' \
      | awk -F '=' '{if ($1=="authentication") {print $2}}' )"
  else
    authorization_token="${request_header_authorization#* }"
  fi
  public_key_file="public_keys/public_key"
  if ! jwt_verify "$authorization_token" $public_key_file; then
    log "jwt signature failed"
    echo_response_status_line 401 "Unauthorized"
    echo_response_default_headers
    echo -e "\r"
    exit
  fi
fi

find_handler_file $request_path

if [[ -n "$request_matching_route_file" ]];then
  RESPONSE_CONTENT="$(echo "$request_content" | $request_matching_route_file $(urldecode ${request_subpath//\// }))"
  if [[ $? -eq 1 ]];then
    echo_response_status_line 500 "Internal Server Error"
    echo_response_default_headers
    echo -e "\r"
    exit 0
  fi
  if [[ "$RESPONSE_CONTENT" =~ ^HTTP\/[0-9]+\.[0-9]+\ [0-9]+ ]];then
    echo "${RESPONSE_CONTENT}"
  else
    echo_response_status_line  
    echo_response_default_headers
    echo -e "Content-Type: text/html\r"
    echo -e "Content-Length: ${#RESPONSE_CONTENT}\r"
    echo -e "\r"
    echo "${RESPONSE_CONTENT}"
  fi
else
  echo_response_status_line 404 "Not Found"
  echo_response_default_headers
  echo -e "\r"
fi

