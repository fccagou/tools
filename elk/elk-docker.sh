#!/bin/sh


#============================================================================
# VARS
#============================================================================

PGM="${PGM:-$(basename "$0")}"
# Variables
RESTORE='\033[0m'
RED='\033[00;31m'
GREEN='\033[00;32m'

#============================================================================
# FUNCTIONS
#============================================================================
usage () {
   cat <<EOF_USAGE

Usage: ${PGM} [ [-e] [-l] [-k] | -a ] [-p] [stack_version]

	-e			: run elastic
	-l			: run logstash
	-k			: run kibana
	-a          : run all stack
	-p			: pull docker images



EOF_USAGE
}

banner () {
  tput clear
  cat <<EOF_BRUCE
*****  *      *    *         *****    ***    ***   *    *  *****  ****
*      *      *   *           *   *  *   *  *   *  *   *   *      *   *
*      *      *  *            *   *  *   *  *      *  *    *      *   *
*      *      * *             *   *  *   *  *      * *     *      *   *
****   *      **              *   *  *   *  *      **      ****   ****
*      *      * *     *****   *   *  *   *  *      * *     *      **
*      *      *  *            *   *  *   *  *      *  *    *      * *
*      *      *   *           *   *  *   *  *   *  *   *   *      *  *
*****  *****  *    *         *****    ***    ***   *    *  *****  *   *



EOF_BRUCE
}


error () {
	echo -e "${RED}[-] ${*}${RESTORE}"
}
warning () {
	echo -e "${RED}[!]${RESTORE} ${*}"
}

action () {
	echo -e "${GREEN}[*] ${*}${RESTORE}"
}

info() {
   printf -- "[*] %s" "${*}"
}


check_cmd() {

   if [ -x "${2}" ]
   then
     info " cmd ${2} ok\n"
   else
     error " cmd ${1} not found..."
     CHECK_ERROR=$(( CHECK_ERROR + 1 ))
   fi
}


#============================================================================
# MAIN
#============================================================================
banner



export DOCKER_CONTENT_TRUST=0

PREFIX="$(cd "$(dirname "$0")"; pwd)"

unset RUN_EL RUN_LOGSTASH RUN_KIBANA PULL


while getopts 'aelkp' c
do
  case $c in
    e) RUN_EL=1 ;;
    l) RUN_LOGSTASH=1 ;;
    k) RUN_KIBANA=1 ;;
    a) RUN_EL=1
       RUN_LOGSTASH=1
       RUN_KIBANA=1
	   ;;
    p) PULL=1 ;;
    *)
		usage
		exit 1
		;;
  esac
  shift
done



VERSION="${1:-latest}"
# Warning: unused
CONFIG="${2:-${PREFIX}/${VERSION}/etc/logstash/config}"
PIPELINE="${3:-${PREFIX}/${VERSION}/etc/logstash/pipeline}"
LOGDIR="${4:-${PREFIX}/${VERSION}/log}"


PRODUCTS='elasticsearch logstash kibana'
DOCKER_REPO='docker.elastic.co'
BEATS='filebeat metricbeat'


if [ -n "${PULL}" ]
then

	info "Pulling ELK STACK version ${VERSION} from ${DOCKER_REPO}\n\n"

	for p in ${PRODUCTS}
	do
		action "Pulling $p ${VERSION}"
	    docker pull "${DOCKER_REPO}/${p}/${p}":"${VERSION}" | grep Status
	    docker tag "${DOCKER_REPO}/${p}/${p}:${VERSION}" "$p":"${VERSION}"
	done

	for b in $BEATS
	do
		action "Pulling beat $b ${VERSION}"
	    docker pull "${DOCKER_REPO}/beats/${b}":"${VERSION}" | grep Status
	    docker tag "${DOCKER_REPO}/beats/${b}":"${VERSION}" "$b":"${VERSION}"
	done

	exit 0
fi


[ ! -d "${LOGDIR}" ] && mkdir -p "${LOGDIR}"

if [ -n "${RUN_EL}" ]
then
    EL_DATA="${PREFIX}/${VERSION}/data/elasticsearch"
    [ ! -d "${EL_DATA}" ] && mkdir -p "${EL_DATA}"
    info "Using direcory as elastic data ${EL_DATA}\n"
    action "Running elasticsearch:${VERSION}\n"
    docker run --rm -p 9200:9200 \
    	-v"${EL_DATA}":/usr/share/elasticsearch/data:Z  \
    	-e "http.host=0.0.0.0" \
    	-e "transport.host=127.0.0.1" \
    	-e "discovery.type=single-node" \
    	-e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    	-e "bootstrap.memory_lock=true" \
        -e "ELASTIC_CONTAINER=true" \
        -e "cluster.name=dobby-cluster" \
        -e "node.name=dobby" \
    	--name="elasticsearch" docker.elastic.co/elasticsearch/elasticsearch:"${VERSION}" > "${LOGDIR}"/elastic.log 2>&1 &

    # -v full_path_to/custom_elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml

    WAIT_SEC="30"
    info "Waiting ${WAIT_SEC} second before health check ...\n"
    sleep ${WAIT_SEC}

    action "Checking Elasticsearch status"
    curl http://127.0.0.1:9200/_cat/health

fi



EL_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' elasticsearch 2>/dev/null)

if [ -z "${EL_IP}" ]
then
	printf -- "[-] Elasticsearch container seems down, I can't is ip. I'm exiting ...\n"
	exit 1
fi

if [ -n "${RUN_LOGSTASH}" ]
then
	action "Running logstash:${VERSION}\n"
	docker run --rm  -p 5000:5000 -p5044:5044 -v"${LOGDIR}":/logs -v "${PIPELINE}":/usr/share/logstash/pipeline:Z --name="logstash" --link elasticsearch:elasticsearch docker.elastic.co/logstash/logstash:"${VERSION}" &

fi

if [ -n "${RUN_KIBANA}" ]
then
	action "Running kibana:${VERSION} / elasticsearch has IP ${EL_IP}\n"
	docker run --rm -p 5601:5601 -e "http.host=0.0.0.0" -e "transport.host=127.0.0.1" --name="kibana" --link elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:"${VERSION}" &

fi

