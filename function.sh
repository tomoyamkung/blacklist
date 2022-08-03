#!/bin/bash
# shellcheck disable=SC3040
set -euo pipefail

PROFILE=$1
IP_ADDRESS="${2}/32"  # TODO 保管される旨を README に追記する
SCOPE=REGIONAL  # CloudFront は対象外なので REGIONAL で固定
IPSETS_NAME=BLACK_LIST  # 対象とする IP Sets の名前は BLACK_LIST で固定

echo "IP_ADDRESS:${IP_ADDRESS}"

echo -n "ID:"
ID=$(aws wafv2 list-ip-sets --output table --scope "${SCOPE}" --profile "${PROFILE}" \
        | grep "${IPSETS_NAME}" | awk '{print $5}')
echo "${ID}"

echo -n "TOKEN:"
TOKEN=$(aws wafv2 get-ip-set --name "${IPSETS_NAME}" --id "${ID}" --scope "${SCOPE}" --profile "${PROFILE}" \
        | grep "LockToken" | tr -d \" | awk '{print $2}')
echo "${TOKEN}"

# echo -n "REGISTERED_IP_ADDRESSES:"  # debug message
REGISTERED=$(aws wafv2 get-ip-set --name "${IPSETS_NAME}" --id "${ID}" --scope "${SCOPE}" --profile "${PROFILE}" \
        | jq '.IPSet.Addresses' | grep -v "\[" | grep -v "\]" | tr -d ' ' | tr -d '"' | tr -d "\n")
# echo "${REGISTERED}"  # debug message

UPDATE_IP_ADDESSES=$(echo '["'"${REGISTERED},$IP_ADDRESS"'"]' | sed -e 's/,/", "/g')
echo "UPDATE_IP_ADDESSES:${UPDATE_IP_ADDESSES}"
aws wafv2 update-ip-set --name "${IPSETS_NAME}" --id "${ID}" --addresses "${UPDATE_IP_ADDESSES}" \
    --lock-token "${TOKEN}" --scope "${SCOPE}" --profile "${PROFILE}" \
    > /dev/null

# 追加されたことを確認するため get-ip-set を実行する
aws wafv2 get-ip-set --name "${IPSETS_NAME}" --id "${ID}" --scope "${SCOPE}" --profile "${PROFILE}"