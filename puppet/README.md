Author: fccagou


modules_install_from_puppetfile  () {
    [ -n "${1}" ] \
        && puppetfile="${1}" \
        || puppetfile="Puppetfile"

   if [ ! -r "${puppetfile}" ]
   then
       error "Can't open ${puppetfile}"
       exit 1
   fi

   
}



puppet-manage env new \
    -n name \
    -e env_dir \
    -d 'description' \
    -c clone_from_url


Create a puppet environment 

Needed data:
- env_dir: where to create new env
- env_name: the name of the new environment
- env_description: discrib the aim of the new env
- clone_from: use an existing skeleton environment

  
  [ -z "${env_dir}" ] && env_dir='.'
  git clone -q --no-hardlink ${clone_from} ${env_dir}/${env_name}
  cd "${env_dir}/${env_name}"
  [ -f "Puppetfile" ] && modules_install_from_puppetfile 


puppet-manage env production



puppet-manage env clone




