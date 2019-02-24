#/bin/sh

# Synoptic
# ======== 
#
# Check env
# Create environment
# Download iso file if not on disk
# Mount the iso as src
# Create dir as dst
# Copy src to dst
# Create ks
# Add necessary material
# Update isolinux conf
# Geniso
#

#============================================================================
# VARS
#============================================================================

PGM=${PGM:-$(basename $0)}
# Variables
RESTORE='\033[0m'
RED='\033[00;31m'
GREEN='\033[00;32m'




#============================================================================
# FUNCTIONS
#============================================================================
usage () {
   cat <<EOF_USAGE

Usage: ${PGM} <iso_label> <iso_source> <iso_sum> <ks_file> <tmpdir> <splash_png>

   iso_label          : label used for new created iso
   iso_source         : si downloaded if prefixed by http[s]:// scheme
   iso_sum            : checksum of iso prefixed by algo:
                        md5: sha{1,224,256,384,512}:
   ks_file            : kickstart file
   tmpdir             : dir used create new iso file.
   splash_png         : set the boot background.
     
EOF_USAGE
}


banner () {
  tput clear
  cat <<EOF_BANNER
                             kO00Okkkxxkkxxxxdddxxxxxxxxxxddddddddddddooooc:,.:co:ldl;:cc;;    
                             0O0Okkkxxxxxxxxxxxolc:;;,;;;:::codddddddoooloo:coxl;,::,,;:c:;.   
                            .KkOkkkkkkkxxxxoc,.................,:cooodollldo:c;':oo;;c;;lc:.   
                            .0kOkkkkkkkxd:'........................':lolooddl::od:':loc;cc:'   
                            :OOOkOkkxkx:'.....,coddxxxxxdolll:,.......;lddddoc:c:,loc,.;cc:,   
                            ck0kOOxkxl'''',:oxkxxdddxxxxdxdxxxxxoc;'....,loooo::,:;c::o:;c:,   
                            lkOkkxkx:,,,:oxdkxxdxdxdxxdddddddddoddddo:...':oool:od:,:cc;,::,   
                            lkOxkkx;;;;oxdxxxxxxxddddxdddooooooooooddddc''';ool:c'.:ol;,,:c,   
                            :0kOOk:;;cddddxxxxxxdddddxdddooolooooooooodoo;,;:lol;col,.coc;:;   
                            '0OOOl::ldooddxdxdxddddddddoooooloollloooooddd:;;col:cc,:olc';:,   
                            '0Okd::ldoodddddoddooooodddoooolllolllllllooooo:;:clc:,;cc:,,,:,   
                            ,0Okcccdolddddoddkxoololooolllolclllllllllllllol,:clc:ldl''lo::'   
                            ;0Odc:ododdddooodkklcccccllccllc:cc::clclcclllll:;clc;c;.ldlc,:'   
                            :Oxllcdodooooooooxxlolloooooc:cccccccclccccllcccl,ccc::cllc,',c'   
                            ckdlccdoooolodlllocoooolooool:clcl:ccllcccccccccc;clc::od:';ooc'   
                            lkolccodolcllocloo:oollloooll:clcccccllllcccc:ccl;:o:;::.;dol;c,   
                            cdooocdoollloolooolclloolloll:llcccclllllllc:::cl;:o:;:odlc;''c,   
                            :oooocodoooolloooooocclclllccllcccccllccccllcc:cl;cl:;:o:;,,loc,   
                            :odool:oolllloooooooooollloolllllclcllcccc::c:ccl'cl;;;,':ddllc'   
                            .olodoccollloooolooooooooooololllcccllcccccccccl:,lc;:oxol:''.c'   
                            .dldddoccolloolllllllolooooolllclccccccccc:::ccc':o;;lo:,;;;llc.   
                            .olddool:;cooolllllololoooollllcccllccc:::::;;,.;ol;:c;,;oxlolc.   
                             codddoll:;collloooooolcllllllc:ccc:::::::;,;:.,cd:;cdd:c:';,'c.   
                             'dxdddooo:,,cllollllccclollclccc:::::::;;,;'..:oo::lc,,::;loc:    
                             .dxxxddxdll:'.;lllcccccllcccccc:::;;;;;;..  .,lcc;col:cxdll::;    
                             ,xkxkxdxxddoc;'..',;ccclccccc::::;;;;''.  ..,:lc::oxo;l:,;,,c,    
                             :kkkkxxxxxxdddlc:,........'''''.....    ..';cod:;c:'':cc:oxlo'    
                             dkkOOkkkkkkxxxdodolc::;,'................,:c:lc;cddocddll:,::.    
                            ldxkOOkOkkkkxkkxxxxdoodollllcc:::;;;,,,,',;,:loc:oo:;c;',lc;l;.    
                           ,kdxxkkxOkkkkkkkxxkkxdddddoooooollcc:;;;;,,;lodcc:l:;:oxolo:ll'     
                           dxxxxxxxOOkkkkkkkxxkkkxddddddoddoool:;;:;:coodl::loo;lc;,;''l:.     
                          :kxxdxxxxkOkOkxxxkkxxkOkxxxddddddoooollllcloodd::c:'':ll:ldoco'.     
                          kxxxodxxxkOkkkxxxkkxdxkkxkxxddddddooolooooooddl;:oddcddl:dc;l:.      
                         .OxxxxoxxxkkOkkxxxkxdddddxxxxxxxdddddoooooolddo;;ll:,cc;,lc::l'.      
                         ckkxxxdxkxkxOkkxkkxxxxxxdxxxxxxxxxddddllolloddl;:ccccdkoldl:l,..      
                         dkOkxxdxkkkkxkkkxkxdxkkkxxxxxkxxxxdddddododddd;;lol:c:,;l:;c:..       
                         OOkkkxdxxxkkxxkkxxxxxxxdlc:;,,,''',;;::cloddo:;cl:;cxxlodo:c..        
                        .OOkOkxdxxxxxkkkkxol:,'...              .:clocc:oddldo::l:,:'..        
                        ,OkkOkxxkkxxxxxl;'...            ...'..,llcol:;coc:lkd;cll;'.';;;,     
                        :Okkkkkkkkxxc,...'.          ...,,;;,,coo:ldoccdolcoc,:ol,';ccllcc;    
                        cxddxkkxkxc'.  ..     .......',;;::;:lod:clc;:odo:dxo:c:,'colollcc:.   
                        ;llll:loo:;'',,,;;;::::cc:;'',;::;:loddccoolcol:;loc;odo,ldollolc:;'   
                         .'''.....;clllcllllllc:c::;''..,lddddl:ool:ldxlllo;ool,lddooolcc;;'   
                           ..........',,:::;,''.......,cooodxl:cc;;lxoccxo:coc;lxxoolccc:;;'   
                              ................    ..;lododxd::ooocloc::dc;ckd:cdxddo:';;,;,.   
                                    .;;,,'... ...,:lodddxdo;:ooc;lxxlcol:co:,cxxxddo:,';','.   
                                   .dxdoc;''.'',:ldddodxxc;:lc;;loc;cxd:cdxcoxkxddoc:,,,,,'.   
                                  .dxxolc::;:clddxxdldxd:;clc::lc:;ll:,:l:;ldkxoool:,',;,,'.   
                                 ;xkkxddoooodxdxxddldxl;:odl;:ooc:odo:ldocdxxxdool:;;,;,,,'.   
                                lkkOOOOkkxxxkkkxddxdo::cdl;,lc:';oc:;llc;odxxdoolc::;,;,;;'.   
                              .dOOOOOOOOOOkkkkxkkkd:;:lc:;cc:;,col::od:cxxkxdoool:::;,;;;,'.   
                             cO0O00OOOOkOkkxxxkOdc;:col::ool;coo:;ldl:ldxxxddoolc::;;,;,,''.   
                           .kO00OOOOOOkkkkkOOkdc;;lxo:;ll:,;lc:':lc;:dxxxdoooooc:::;;;;,'''.   
                          l000000OOOkkkOkkkxo:,;ldo;,llc,,cll::ddl:lxdxdooooolc:;::;;;;,;''.   
                        .x0K0OOOOOOkkkkkkxl;';cl:,;coc::ldl::odc;cdxdddoooooolc:;:;,,,,,;,'.   
                       .OOOOOOOOkxxdxxkdc,';clc;:odl::llc;,llc;cxxxdoodooollol::::;,,,,,;,'    
                      .OOkkkkkkxxxxxdl;',:ooc:cooc;;llc,;ccc:lodxxdxxdoollloc::::::,,,,,,''    
                      xkkkkkxkxxkdl;'';cdoc:lol:,:ol:clollcloddxxxxxxddollllc:c:::;,,,,,,,.    

EOF_BANNER
}

error () {
	echo -e "${RED}[-] ${*}${RESTORE}"
}
warning () {
	echo -e "${RED}[!]${RESTORE} ${*}"
}

action () {
	echo -e "${GREEN}[+] ${*}${RESTORE}"
}

info() {
   printf -- "[-] ${*}"
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

[ $# != 6 ] && usage && exit 1


ISO_LABEL="${ISO_LABEL:-${1}}"
ISO_SRC="${ISO_SRC:-${2}}"
ISO_SUM="${ISO_SUM:-${3}}"
KS_FILE="${KS_FILE:-${4}}"
TMPDIR="${TMPDIR:-${5}}"
SPLASH="${SPLASH:-${6}}"


UDISKCTL="$(which udisksctl 2>/dev/null)"
RSYNC="$(which rsync 2>/dev/null)"
#MKISOFS="$(which mkisofs 2>/dev/null)"
MKISOFS="$(which genisoimage 2>/dev/null)"
MKTEMP="$(which mktemp 2>/dev/null)"
SUMCMD="$(which ${ISO_SUM/:*/}sum 2>/dev/null)"
CURL="$(which curl 2>/dev/null)"
WGET="$(which wget 2>/dev/null)"
ISOINFO="$(which isoinfo 2>/dev/null)"


SCHEME="${ISO_SRC/:*/}"



action 'Checking env'
CHECK_ERROR=0
check_cmd "udiskctl" ${UDISKCTL}
check_cmd "rsync" ${RSYNC}
check_cmd "mkisofs" ${MKISOFS}
check_cmd "isoinfo" ${ISOINFO}
check_cmd "mktemp" ${MKTEMP}
check_cmd "${ISO_SUM/:*/}sum" ${SUMCMD}

[ ${CHECK_ERROR} -gt 0 ] && error "exiting..." && exit 1


ISO_SUM="${ISO_SUM/*:/}"


case "${SCHEME}" in
    "${ISO_SRC}" )
      # Nothing to download
      SCHEME=""
      :
    ;;

    "http"|"https"|"ftp"|"ftps")
    
        if [ -x "${CURL}" ]
        then
            DOWNLOADCMD="${CURL} -s -k -O"
        else
            if [ -x "${WGET}" ]
            then
                DOWNLOADCMD="${WGET}"
            else
                error "No downloader tool found (curl, wget) ... exiting..."
                exit 1
            fi
        fi

    ;;
    *)
       error "${SCHEME} type not is not known by us... exiting ..."
       exit 1
    ;;
esac


[ ! -f "${KS_FILE}" ] \
  && error "ks file (${KS_FILE}) does not exsts ... exiting ..." \
  && exit 1
 

action 'Create working environment'

if [ -z "${TMPDIR}" ]
then
   TMPDIR=$( ${MKTEMP} -d )
else
   [ -d ${TMPDIR} ] \
   &&  error "TMPDIR ${TMPDIR} exists...Exiting..." \
   &&  exit 1

   mkdir -p "${TMPDIR}"
fi
info " in ${TMPDIR}\n"

[ ! -d ${TMPDIR} ] \
   &&  error "Creating ${TMPDIR}...Exiting..." \
   &&  exit 1

# GOTO TMPDIR
cd ${TMPDIR}


DSTDIR="${TMPDIR}/dst"
mkdir -p ${DSTDIR}

ISO_DST="${ISO_DST:-${TMPDIR}/${ISO_LABEL}.iso}"

if [ -n "${SCHEME}" ]
then
    action 'Downloading iso file'
    info "   ${ISO_SRC}\n"
    ${DOWNLOADCMD} ${ISO_SRC}
    ISO_SRC="${TMPDIR}/${ISO_SRC##*/}"
fi

[ ! -f ${ISO_SRC} ] &&  error "Iso file ${ISO_SRC} not found ...Exiting..." &&  exit 1


action "Checking checksum"
info "${ISO_SRC}\n"

if [ -n "${ISO_SUM}" ]
then
    CHECKSUM="$(${SUMCMD} ${ISO_SRC} | awk '{ print $1 }')" 
    
    [ "${ISO_SUM}" != "${CHECKSUM}" ] && error "Checksum error (${CHECKSUM})... Exiting ..." && exit 1
fi


action 'Mount the iso as src '
${UDISKCTL} loop-setup -r -f ${ISO_SRC}

# Dans le cas de Arch linux par exemple, le montage ne se fait pas
# forcement automatiquement. Il faut faire un mount.
# Mais quelle partition monter ?
# Une idée est de regarder le Volume id de l'iso et d'utiliser le /dev/disk/by-path'
#
LOOP_LINK="$(readlink -f "/dev/disk/by-label/$(isoinfo -i ${ISO_SRC} -d 2>/dev/null | grep 'Volume id' | sed -e 's/[^:]*: //' -e 's/ /\\x20/g')")"

${UDISKCTL} mount -b ${LOOP_LINK}

# TESTER LE RETOUR
# TROUVER LE POINT DE MONTAGE
MOUNTDIR="$(mount -t iso9660 | sed 's/^.* on \(.*\) type .*/\1/')"

[ ! -d "${MOUNTDIR}" ] \
  && error "Mount point error [${MOUNTDIR}]..." \
  && error "Exiting..." \
  exit 1

action 'Create dir as dst'
mkdir -p "${DSTDIR}"

action 'Copy src to dst'
${RSYNC} -a "${MOUNTDIR}"/* ${DSTDIR}/
#FIXME: Why ??  ${RSYNC} -a "${MOUNTDIR}"/.discaction  ${DSTDIR}/

action "Umount source ${MOUNTDIR}"
${UDISKCTL} unmount -b ${LOOP_LINK}
${UDISKCTL} loop-delete -b ${LOOP_LINK}

action 'Create ks'
mkdir ${DSTDIR}/ks
cp "${KS_FILE}" ${DSTDIR}/ks/ks.cfg

if [ -n "${SPLASH}" ]
then
  [ ! -f "${SPLASH}" ] \
  && error "splash file (${SPLASH}) does not exsts ... exiting ..." \
  && exit 1

  action "Copying splash ${SPLASH}"
  cp ${SPLASH} ${DSTDIR}/isolinux/splash.png
fi

action 'Add necessary material'
action 'Update isolinux conf'
SRC_LABEL="${MOUNTDIR//*\//}"
info "TODO ${SRC_LABEL}\n"
#sed -i "s/${SRC_LABEL}/${ISO_LABEL}/g" ${DSTDIR}/isolinux/isolinux.cfg
sed -i "s/menu default//g" ${DSTDIR}/isolinux/isolinux.cfg


cat >> ${DSTDIR}/isolinux/isolinux.cfg  <<EOF_ISO
label ${ISO_LABEL}
  menu label ^${ISO_LABEL}
  menu default
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=${ISO_LABEL} ks=hd:LABEL=${ISO_LABEL}:/ks/ks.cfg quiet
EOF_ISO

action "Geniso ${ISO_DST}"
cd $DSTDIR

# Cas genisofs
 ${MKISOFS} -o ${ISO_DST} \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -V "${ISO_LABEL}" \
        -boot-load-size 4 \
        -boot-info-table \
        -R -J  -T ./ \
        2>>${TMPDIR}/geniso.log \
        >>${TMPDIR}/geniso.log

if [  "${?}" != "0" ]
then
   error " During GEN ISO ${ISO_DST}"
   info  " Look in ${TMPDIR}/geniso.log\n"
   exit 1
fi

# Si mkisofs
# ${MKISOFS} -o ${ISO_DST} \
#         -b isolinux.bin \
#         -c boot.cat \
#         -no-emul-boot \
#         -V "${ISO_LABEL}" \
#         -boot-load-size 4 \
#         -boot-info-table \
#         -R -J -v -T isolinux/
# 


action "Make test"
info "Run  next cmd for test\n\n"
info "  qemu-system-x86_64 -cdrom ${ISO_DST} -m 512\n\n" 

