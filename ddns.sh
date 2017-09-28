#!/bin/bash
set -e


file_path=$(dirname "$(readlink -f "$0")")
source ${file_path}/config.sh

# LOGGER
log() {
  if [ "${1}" ]; then
    echo -e "${1}"
    echo -e "[$(date)] - ${1}" >> ${file_path}/${log_name}
  fi
}

# SCRIPT START
log "Check Initiated"

ip=$(curl -s http://ipv4.icanhazip.com)
log "Current IP: ${ip}"

zone_id=$(curl -s -X GET "${api_url}?name=${zone_name}" \
  -H "X-Auth-Email: ${auth_email}" -H "X-Auth-Key: ${auth_key}" \
  -H "Content-Type: application/json" | \
  grep -oP '(?<="id":")[^"]*' | head -1 )

record=$(curl -s -X GET "${api_url}/${zone_id}/dns_records?name=${record_name}" \
  -H "X-Auth-Email: ${auth_email}" -H "X-Auth-Key: ${auth_key}" \
  -H "Content-Type: application/json") 

record_id=$(echo "${record}" | grep -oP '(?<="id":")[^"]*')

record_ip=$(echo "${record}" | grep -oP '(?<="content":")[^"]*')
log "Record IP: ${record_ip}"

if [[ ${record_ip} == ${ip} ]]; then
  msg="No IP change required"
  log "${msg}"
  exit 0
fi

update=$(curl -s -X PUT "${api_url}/${zone_id}/dns_records/${record_id}" \
  -H "X-Auth-Email: ${auth_email}" \
  -H "X-Auth-Key: ${auth_key}" -H "Content-Type: application/json" \
  --data "{\"id\":\"${zone_id}\",\"type\":\"A\",\"name\":\"${record_name}\",\"content\":\"${ip}\",\"proxied\":true}")

if [[ ${update} == *"\"success\":false"* ]]; then
  msg="API UPDATE FAILED:\n${update}"
  log "${msg}"
  exit 1 
else
  msg="IP changed to: ${ip}"
  log "${msg}"
fi
