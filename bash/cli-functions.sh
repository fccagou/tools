


# From pi-hole

COL_NC='\e[0m' # No Color
COL_LIGHT_GREEN='\e[1;32m'
COL_LIGHT_RED='\e[1;31m'
TICK="[${COL_LIGHT_GREEN}✓${COL_NC}]"
CROSS="[${COL_LIGHT_RED}✗${COL_NC}]"
INFO="[i]"
# shellcheck disable=SC2034
DONE="${COL_LIGHT_GREEN} done!${COL_NC}"
OVER="\\r\\033[K"



action () {
	printf -- "%b %s" "${INFO}" "${@}"
}

ok () {
	printf -- "%b%b %s\\n" "${OVER}" "${TICK}" "${@}"
}

error () {
	printf -- "%b%b %s\\n" "${OVER}" "${CROSS}" "${@}"
}


job_s_done () {
	printf -- "%b\\n" "${DONE}"
}


random_test () {
	return $(( $RANDOM % 3 ))
}

test_ok () {
	return 0
}

test_ko () {
	return 1
}



for t in $(seq 1 3)
do
    msg="Running test ${t}"
    action "${msg}"
    sleep 3
	random_test && ok "${msg}" || error "${msg} (error is ${?})"
done


job_s_done


