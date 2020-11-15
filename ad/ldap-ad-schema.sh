#!/bin/sh
# Author: François CHENAIS <me@fccagou.fr>
# LICENCE: GNU GENERAL PUBLIC LICENSE Version 2, June 1991
#
# Search informations in ldap AD schema.
# links: https://ldapwiki.com/wiki/
#
# ALL Domain conotrollers
#
#     (&(objectCategory=Computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))
#
# ALL Global catalog
#
#    (&(objectCategory=nTDSDSA)(options:1.2.840.113556.1.4.803:=1))
#
# exclude domain controller
#
#    (!(primaryGroupID=516))
#
#  Excludes OpsMgr Management Servers and Gateways#
#
#     (!(servicePrincipalName=MSOMHSvc/*))
#
# Returns odd servers if their netbios names end with a number (e.g. AnySrv101)#
#
#     (|(name=*1)(name=*3)(name=*5)(name=*7)(name=*9))
#
# All computer accounts which are Administratively Disabled:#
#
#     (&(objectClass=computer)(userAccountControl:1.2.840.113556.1.4.803:=2))
#
# Computers By Operating System Version#
#
# Find all Windows Server 2003 Non-DCs#
#
#    (&(&(&(samAccountType=805306369)(!(primaryGroupId=516)))(objectCategory=computer)(operatingSystem=Windows Server 2003*)))
#
# Find all 2003 Servers - DCs#
#
#    (&(&(&(samAccountType=805306369)(primaryGroupID=516)(objectCategory=computer)(operatingSystem=Windows Server 2003*))))
#
# Find all Server Windows Server 2008#
#
#    (&(&(&(&(samAccountType=805306369)(!(primaryGroupId=516)))(objectCategory=computer)(operatingSystem=Windows Server 2008*))))
#
# Find all Windows 2000 SP4 computers#
#
#    (&(&(&(objectCategory=Computer)(operatingSystem=Windows 2000 Professional)(operatingSystemServicePack=Service Pack 4))))
#
# Find all Windows XP SP2 computers#
#
#    (&(&(&(&(&(&(&(objectCategory=Computer)(operatingSystem=Windows XP Professional)(operatingSystemServicePack=Service Pack 2))))))))
#
# Find all Windows XP SP3 computers#
#
#    (&(&(&(&(&(&(&(objectCategory=Computer)(operatingSystem=Windows XP Professional)(operatingSystemServicePack=Service Pack 3))))))))
#
# Find all Windows Vista SP1 computers#
#
#    (&(&(&(&(sAMAccountType=805306369)(objectCategory=computer)(operatingSystem=Windows Vista*)(operatingSystemServicePack=Service Pack 1)))))
#
# Tools:
# https://github.com/stufus/ADOffline/blob/master/adoffline.py
#

error () {
    printf -- "[-] %s\n" "${@}"
}

warning () {
    printf -- "[*] %s\n" "${@}"
}


usage () {

    cat <<EOF_USAGE
Usage $(basename "${0}" ) [-h] [-u uri] [-b base_dn] [ -f query_filter ] [-l query_limit] -t <object_type> [type_options]

    -h                : this help
    -u uri            : ldap uri. If not set, use defaut ldap conf
    -b base_dn        : ldap base dn: if not set, use default ldap conf
    -t object_type    : object type
    -D                : show data
    -f query_filter   : ldap query filter
    -l query_limit    : ldap query limit (integer, none or max)
	                    default: 1000
    type_options      : parameters depends of object type.


OBECT TYPES

   schema         : search in ldap schema
   group          : search for groups objectClass
   user           : search for user objectClass
   computer       : search for computer objectClass
   risk           : search for risk objectClass

SCHEMA TYPE OPTIONS

   opt            : Optional constructed attributes
   no_rep         : not replicated attributes
   link           : linked attributes
   indexed        : indexed attributes
   confidential   : confidential attributes
   all            : all attributes
   anr            : ambiguous name resolution


EOF_USAGE

}



ad_schema_search () {

    uri="${1}"
    basedn="${2}"
    show_data="${3}"
    query_filter="${4}"
    query_limit="${5}"
    schema_attrs="${6}"
    shift; shift; shift; shift;shift;shift;

    case "${schema_attrs}" in
   	opt)            # Optional constructed attributes
           ldap_filter='(&(objectCategory=attributeSchema)(systemFlags:1.2.840.113556.1.4.803:=4))'
           ;;
   	no_rep)         # not replicated attributes
           ldap_filter='(&(objectCategory=attributeSchema)(systemFlags:1.2.840.113556.1.4.803:=1))'
           ;;
   	link)           # linked attributes
           ldap_filter='(linkID=*)'
           ;;
   	indexed)        # indexed attributes
           ldap_filter='(searchFlags:1.2.840.113556.1.4.803:=1)'
           ;;
   	confidential)   # confidential attributes
           ldap_filter='(searchFlags:1.2.840.113556.1.4.803:=128)'
           ;;
   	all)            # all attributes
           ldap_filter='(&(objectCategory=attributeSchema)(isMemberOfPartialAttributeSet=TRUE))'
           ;;
   	anr)            # ambiguous name resolution
           ldap_filter='(searchFlags:1.2.840.113556.1.4.803:=4)'
           ;;

          *) error "Bad schema query option"; usage; exit 1 ;;
    esac


    [ -n "${query_filter}" ] \
      && ldap_filter="(&${ldap_filter}(${query_filter}))"

    if [ "${show_data}" = "0" ]
    then
        ldapsearch -Q -LLL \
			   -H "${uri}" \
               -b "cn=Schema,cn=Configuration,${basedn}" \
               -s sub \
               -a always \
               -z "${query_limit}" \
               "${ldap_filter}" \
               "cn" "lDAPDisplayName" "linkID" "objectClass"
     else
        ldapsearch -Q -LLL \
			   -H "${uri}" \
               -b "cn=Schema,cn=Configuration,${basedn}" \
               -s sub \
               -a always \
               -z "${query_limit}" \
               "${ldap_filter}" "${@}"
     fi

}

ad_group_search () {

    warning "ad_group_search not yet implemented\n"
}


ad_user_search () {

    warning "ad_user_search not yet implemented\n"
}



ad_computer_search () {

    warning "ad_computer_search not yet implemented\n"
}

ad_risk_search () {

    warning "ad_risk_search not yet implemented\n"
}

show_data=0
uri="$(grep ^URI /etc/openldap/ldap.conf|cut -d' ' -f2)"
# TODO: get data in ldap.conf, krb5.conf ...
basedn="$(grep ^BASE /etc/openldap/ldap.conf|cut -d' ' -f2 |  sed 's/[^,]*,//' )"
query_filter=''
query_limit="1000"

while getopts "hu:b:t:Df:l:" option; do
    case "${option}" in
        h) usage; exit 0 ;;
        D) show_data=1 ;;
        u) uri=${OPTARG} ;;
        b) basedn=${OPTARG} ;;
        t) query_type="${OPTARG}" ;;
        f) query_filter="${OPTARG}" ;;
        l) query_limit="${OPTARG}" ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))


case "${query_type}" in
     schema)
        ad_schema_search "${uri}" "${basedn}" "${show_data}" "${query_filter}" "${query_limit}" "${@}"
        ;;
     group)
        ad_group_search "${uri}" "${basedn}" "${show_data}" "${query_filter}" "${query_limit}" "${@}"
        ;;
     user)
        ad_user_search "${uri}" "${basedn}" "${show_data}" "${query_filter}" "${query_limit}" "${@}"
        ;;
     computer)
        ad_computer_search "${uri}" "${basedn}" "${show_data}" "${query_filter}" "${query_limit}" "${@}"
        ;;
     risk)
        ad_risk_search "${uri}" "${basedn}" "${show_data}" "${query_filter}" "${query_limit}" "${@}"
        ;;
     *)  error "Query type needed\n\n"
         usage; exit 1 ;;
esac





