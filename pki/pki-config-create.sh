#!/bin/bash
set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
	cat <<-EOF_USAGE
Usage: $cmd [--help]

Génère le fichier de configuration "${CONFIG_FILE}"

Liste des variables surchargeables:

  Commun:
    CA_DIR                       : Chemin de la CA (${CA_DIR})
    DAYS                         : Durée de validité en jours ($DAYS)

  Requêtes:

    REQ_COUNTRYNAME_DEFAULT      : Pays par défaut pour les requêtes (${REQ_COUNTRYNAME_DEFAULT})
    REQ_STATE_DEFAULT            : état par défaut  (${REQ_STATE_DEFAULT})
    REQ_ORGANIZATIONNAME_DEFAULT : nom de l'organisation par défaut (${REQ_ORGANIZATIONNAME_DEFAULT})

  Challenge mdp:

    CHALLENGEPASSWORD_MIN         : Taille minimale (${CHALLENGEPASSWORD_MIN})
    CHALLENGEPASSWORD_MAX         : Taille maximale (${CHALLENGEPASSWORD_MAX})


EOF_USAGE
}



# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
DAYS="${DAYS:-365}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"


REQ_COUNTRYNAME_DEFAULT="${REQ_COUNTRYNAME_DEFAULT:-VU}"
REQ_STATE_DEFAULT="${REQ_STATE_DEFAULT:-Efate}"
REQ_ORGANIZATIONNAME_DEFAULT="${REQ_ORGANIZATIONNAME_DEFAULT:-Personnal}"

CHALLENGEPASSWORD_MIN="${CHALLENGEPASSWORD_MIN:-4}"
CHALLENGEPASSWORD_MAX="${CHALLENGEPASSWORD_MAX:-20}"


[ "$#" -ge "1" ] && [ "$1" == "--help" ] && {
    usage
    exit 1
} || :



cat > "${CONFIG_FILE}" <<EOF_CONFIG
# *****************************************************************************
#
#    WARNING: This file is generated by ${0##*}.sh
#
# *****************************************************************************
#
# Exemples from:
#
# - https://github.com/drduh/config/blob/master/openssl.cnf
# - https://github.com/openssl/openssl/blob/master/apps/openssl.cnf
#
#
#
# -----------------------------------------------------------------------------
# CA
# -----------------------------------------------------------------------------
[ ca ]
default_ca = CA_default

[ CA_default ]
dir              = ${CA_DIR}               # Where everything is kept
certs            = \$dir/certs             # Where the issued certs are kept
crl_dir          = \$dir/crl               # Where the issued crl are kept
database         = \$dir/index.txt         # database index file
new_certs_dir    = \$dir/newcerts          # default place for new certs
certificate      = \$dir/cacert.pem        # The CA certificate
serial           = \$dir/serial            # The current serial number
crlnumber        = \$dir/crlnumber         # the current crl number
crl              = \$dir/crl.pem           # The current CRL
private_key      = \$dir/private/cakey.pem # The private key
RANDFILE         = \$dir/private/.rand     # private random number file
x509_extensions  = usr_cert               # The extensions to add to the cert
name_opt         = ca_default             # Subject Name options
cert_opt         = ca_default             # Certificate field options
default_days     = $DAYS                    # how long to certify for
default_crl_days = 30                     # how long before next CRL
default_md       = default                # use public key default MD
preserve         = no                     # keep passed DN ordering
policy           = policy_match

# ----- CA extenstion

[ usr_cert ]

# These extensions are added when 'ca' signs a request.
# This goes against PKIX guidelines but some CAs do it and some software
# requires this to avoid interpreting an end user certificate as a CA.
basicConstraints=CA:FALSE
# This is typical in keyUsage for a client certificate.
# keyUsage = nonRepudiation, digitalSignature, keyEncipherment

# PKIX recommendations harmless if included in all certificates.
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

# This stuff is for subjectAltName and issuerAltname.
# Import the email address.
# subjectAltName=email:copy
# An alternative to produce certificates that aren't
# deprecated according to PKIX.
# subjectAltName=email:move
# Copy subject details
# issuerAltName=issuer:copy
# This is required for TSA certificates.
# extendedKeyUsage = critical,timeStamping

# ----- CA policies

[ policy_match ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

# -----------------------------------------------------------------------------
# REQUESTS
# -----------------------------------------------------------------------------
[ req ]
default_bits       = 4096
default_md         = sha512
distinguished_name = req_distinguished_name
attributes         = req_attributes

[ req_distinguished_name ]
countryName			    = Country Name (2 letter code)
countryName_default		= ${REQ_COUNTRYNAME_DEFAULT}
countryName_min			= 2
countryName_max			= 2

stateOrProvinceName		    = State or Province Name (full name)
stateOrProvinceName_default	= ${REQ_STATE_DEFAULT}

localityName			= Locality Name (eg, city)

0.organizationName		    = Organization Name (eg, company)
0.organizationName_default	= ${REQ_ORGANIZATIONNAME_DEFAULT}

# we can do this but it is not needed normally :-)
#1.organizationName		= Second Organization Name (eg, company)
#1.organizationName_default	= World Wide Web Pty Ltd

organizationalUnitName		    = Organizational Unit Name (eg, section)
#organizationalUnitName_default	=

commonName			    = Common Name (e.g. server FQDN or YOUR name)
commonName_max			= 64
emailAddress			= Email Address
emailAddress_max		= 64

# SET-ex3			= SET extension number 3

[ req_attributes ]
# TODO: change this values for max
challengePassword     = A challenge password
challengePassword_min = ${CHALLENGEPASSWORD_MIN}
challengePassword_max = ${CHALLENGEPASSWORD_MAX}



# -----------------------------------------------------------------------------
# Extensions
# -----------------------------------------------------------------------------
# Used for Root CA Certificate
[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical,CA:TRUE
keyUsage               = critical,cRLSign,keyCertSign


# For client certificats
[ tls_client ]
nsCertType       = client
basicConstraints = CA:FALSE
extendedKeyUsage = clientAuth
keyUsage         = critical, digitalSignature, keyEncipherment, dataEncipherment

# For server certificates
[ tls_server ]
nsCertType           = server
basicConstraints     = CA:FALSE
extendedKeyUsage     = serverAuth
keyUsage             = critical, digitalSignature, keyEncipherment
subjectKeyIdentifier = hash
EOF_CONFIG

echo "Fichier de configuration créé ${CONFIG_FILE}"

