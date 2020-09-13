#!/bin/sh

if [ "${1}" = "-v" ]
then
  verbose="-v"
  shift
else
  verbose="--silent"
fi

api="${1}"

myself="$(hostname -f)"

puppet_ssl_dir="$(puppet config print ssldir)"
puppet_ca="${puppet_ssl_dir}/certs/ca.pem"
puppet_cert="${puppet_ssl_dir}/certs/${myself}.pem"
puppet_key="${puppet_ssl_dir}/private_keys/${myself}.pem"
method='GET'


case "${api}" in
    "delete_cache" )
      method='DELETE'
      api='/puppet-admin-api/v1/environment-cache'
      ;;
    "env_list")
	  # ./puppet-request-api.sh  env_list | jq -Mr '.environments|keys[]'
	  api='/puppet/v3/environments'
	  ;;
    *)
      method='GET'
      ;;
esac



/usr/bin/curl --cacert "${puppet_ca}" --key "${puppet_key}" --cert "${puppet_cert}" \
    "${verbose}" -X "${method}" \
    "https://${myself}:8140${api}"

