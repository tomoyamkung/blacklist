#!/bin/bash
# shellcheck disable=SC3040
set -euo pipefail


function usage() {
    cat <<EOF 1>&2
Description:
    $(basename "${0}") is a tool that adds an IP address to your AWS WAF. The IP address is added to the IP set called BLACK_LIST.
    [Caution] Please register BLACK_LIST in advance.

    function.sh は AWS WAF に IP アドレスを追加するツールです。この IP アドレスは BLACK_LIST という IP Sets に追加されます。
    【注意】BLACK_LIST は事前に登録しておいてください。

Usage:
    $(basename "${0}") --profile PROFILE_NAME ip_address

Options:
    --help      print this.
                これを出力します。
    --profile   Specify the profile of the AWS account to which you want to add the IP address.
                IP アドレスを追加したい AWS アカウントのプロファイルを指定します。

Caution:
    ip_address  Since only CIDR addresses of / 8, / 16, / 24, / 32 can be registered, "/ 32" is automatically added to the argument address.
                登録できるアドレスは /8, /16, /24, /32 の CIDR アドレスのみとなるため、引数のアドレスに "/32" を自動で追加します。
EOF
}


while (( $# > 0 ))
do
    case $1 in
        --help)
            usage
            exit 1
            ;;
        --profile)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "'option' requires an argument." 1>&2
                exit 1
            else
                PROFILE="${2}"
                echo "PROFILE:${PROFILE}"
                shift
            fi
            ;;
        -*)
            usage
            exit 1
            ;;
        *)
            IP_ADDRESS="${1}/32"
            echo "IP_ADDRESS:${IP_ADDRESS}"
            ;;
    esac
    shift
done


# 定数定義
SCOPE=REGIONAL  # CloudFront は対象外なので REGIONAL で固定
IPSETS_NAME=BLACK_LIST  # 対象とする IP Sets の名前は BLACK_LIST で固定


function generate_addresses() {
    # specifications: must be array for JSON format.
    # JSON の配列で指定する仕様になっている。
    # for example: ["192.0.2.44/32", "192.0.2.0/24", "192.0.0.0/16"]

    local registered
    registered=$(aws wafv2 get-ip-set --name "${IPSETS_NAME}" --id "${ID}" --scope "${SCOPE}" --profile "${PROFILE}" \
            | jq '.IPSet.Addresses' | grep -v "\[" | grep -v "\]" | tr -d ' ' | tr -d '"' | tr -d "\n")

    local update_ip_addesses
    update_ip_addesses=$(echo '["'"${registered},${1}"'"]' | sed -e 's/,/", "/g')
    echo "${update_ip_addesses}"
}

echo -n "ID:"
ID=$(aws wafv2 list-ip-sets --output table --scope "${SCOPE}" --profile "${PROFILE}" \
        | grep "${IPSETS_NAME}" | awk '{print $5}')
echo "${ID}"

echo -n "TOKEN:"
TOKEN=$(aws wafv2 get-ip-set --name "${IPSETS_NAME}" --id "${ID}" --scope "${SCOPE}" --profile "${PROFILE}" \
        | grep "LockToken" | tr -d \" | awk '{print $2}')
echo "${TOKEN}"

UPDATE_IP_ADDESSES=$(generate_addresses "${IP_ADDRESS}")
echo "UPDATE_IP_ADDESSES:${UPDATE_IP_ADDESSES}"

aws wafv2 update-ip-set --name "${IPSETS_NAME}" --id "${ID}" --addresses "${UPDATE_IP_ADDESSES}" \
    --lock-token "${TOKEN}" --scope "${SCOPE}" --profile "${PROFILE}" \
    > /dev/null

# Run get-ip-set to confirm that it has been added.
# 追加されたことを確認するため get-ip-set を実行する。
aws wafv2 get-ip-set --name "${IPSETS_NAME}" --id "${ID}" --scope "${SCOPE}" --profile "${PROFILE}"

exit 0