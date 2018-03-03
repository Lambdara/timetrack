_complete_track()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${#COMP_WORDS[@]}" in
        2)
            opts="init start stop git summarize status"

            ;;
        3)
            case "$prev" in
                "start"|"summarize")
                    local var
                    dir=$HOME/.timetrack/
                    opts=$(find $dir -mindepth 1 -type d | cut -c$((${#dir}+1))-)
                    ;;
            esac
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}

complete -F _complete_track track
