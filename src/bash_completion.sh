# Timetrack - Timetracking software following the Unix philosophy
# Copyright (C) 2018  Uwila
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

_complete_track()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    function timetrack_files {
        dir=$HOME/.timetrack/
        opts=$(find $dir -mindepth 1 -type d -not -path "$dir.git" -not -path "$dir.git/*" | cut -c$((${#dir}+1))-)
    }

    case "${#COMP_WORDS[@]}" in
        2)
            opts="init start stop git summarize status list"
            ;;
        3)
            case "$prev" in
                "start"|"summarize"|"list")
                    timetrack_files
                    ;;
            esac
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}

complete -F _complete_track track
