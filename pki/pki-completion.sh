__cmd_list () {
	local cmd
	cmd="${1:-""}"
	ls pki-"$cmd"*.sh | sed -e "s/pki-$cmd[-]*//" -e 's/\.sh$//' | cut -d\- -f1 | sort | uniq
}

_pki_completion () {

	case "${#COMP_WORDS[@]}" in
		0|1) return ;;
		2)
		    COMPREPLY=( $(compgen -W "$(__cmd_list)" -- "${COMP_WORDS[1]}" ))
			;;
		*)
			nb=${#COMP_WORDS[@]}
			local cmd
			cmd="$( printf -- '%s-' "${COMP_WORDS[@]}" | cut -d- -f2-$(( nb - 1 )) )"
			#COMPREPLY=( $(compgen -W "$(__cmd_list "${COMP_WORDS[1]}")" -- "${COMP_WORDS[2]}" ))
			COMPREPLY=( $(compgen -W "$(__cmd_list "$cmd")" -- "${COMP_WORDS[-1]}" ))
			;;
	esac
}

complete -F _pki_completion pki.sh
complete -F _pki_completion pki
