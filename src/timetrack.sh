#!/bin/bash

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

datadir=$HOME/.timetrack
tmpdir=/tmp/$(whoami)-timetrack-running

function init {
    if (( $# != 0 )); then
        echo "Usage: track init" 1>&2
        exit 1;
    fi

    if [[ -d $datadir ]]; then
        echo "Already initialized"
        exit 1
    fi

    mkdir $datadir
}

function now {
    echo "$(date +%s)"
}

function git_initialized {
    if [[ -d "$datadir/.git" ]]; then
        true
    else
        false
    fi
}

function start {
    if (( $# != 1 )); then
        echo "Usage: track start <label>" 1>&2
        exit 1
    fi

    now=$(now)
    dir=$datadir/$1
    filename=$dir/$now

    mkdir -p $dir
    mkdir -p $tmpdir

    echo $now > $filename
    tmpfile=$tmpdir/$(cat /dev/urandom | tr -cd 'a-z0-9' | head -c 32)
    ln -s $filename $tmpfile

    if [[ git_initialized ]]; then
        git -C $datadir add $filename
        git -C $datadir commit -m "Start tracking $1"
    fi
}

function stop {
    if (( $# != 0 )); then
        echo "Usage: track stop" 1>&2
        exit 1
    fi

    now=$(now)

    for file in $tmpdir/*; do
        echo $now >> $file
        rm $file
    done

    if git_initialized; then
        git -C $datadir commit -am "Stop tracking"
    fi
}

function summarize {
    if (( $# > 1 )); then
        echo "Usage: track summarize [label]" 1>&2
        exit 1
    fi

    total=0
    for file in $(find $datadir/$1 -type f -not -path "$datadir/.git/*"); do
        line_amount=$(wc -l < $file)
        if [[ "$line_amount" == "2" ]]; then
            readarray file_content < $file
            total=$((total+${file_content[1]}-${file_content[0]}))
        fi
    done

    hours=$((total/3600))
    minutes=$(((total%3600)/60))
    seconds=$((total%60))

    printf '%d hours, %d minutes, %d seconds\n' $hours $minutes $seconds
}

function list {
    if (( $# > 1 )); then
        echo "Usage: track list [label]" 1>&2
        exit 1
    fi

    for file in $(find $datadir/$1 -type f -not -path "$datadir/.git/*"); do
        line_amount=$(wc -l < $file)
        if [[ "$line_amount" == "2" ]]; then
            readarray file_content < $file
            time_spent=$((total+${file_content[1]}-${file_content[0]}))

            hours=$((time_spent/3600))
            minutes=$(((time_spent%3600)/60))
            seconds=$((time_spent%60))

            file=${file#$datadir/}

            printf 'Tracked %s for %d:%d:%d hours, from %s to %s\n' \
                   $(dirname $file) \
                   $hours \
                   $minutes \
                   $seconds \
                   "$(date -d @${file_content[0]} +'%Y-%m-%d %H:%M:%S')" \
                   "$(date -d @${file_content[1]} +'%Y-%m-%d %H:%M:%S')"
        fi
    done
}

function status {
    if (( $# != 0 )); then
        echo "Usage: track status" 1>&2
        exit 1
    fi

    if [[ -d $tmpdir ]]; then
        for file in $(find $tmpdir/ -type l); do
            file=$(readlink $file)
            file=${file#$datadir/}
            filename=$(basename $file)
            echo "Tracking $(dirname $file) since $(date -d @$filename +'%Y-%m-%d %H:%M:%S')"
        done
    fi
}

function run_git {
    if [[ "$1" == "init" ]]; then
        git -C $datadir init
        git -C $datadir add $datadir
        git -C $datadir commit -m 'Initialize Timetrack history'
    else
        git -C $datadir ${@:1}
    fi
}

function remove {
    if (( $# != 1 )); then
        echo "Usage: track remove <label>" 1>&2
        exit 1
    fi

    rm -r $datadir/$1

    if git_initialized; then
        git -C $datadir add $1
        git -C $datadir commit -m "Remove $1"
    fi
}

function insert {
    if (( $# != 3 )); then
        echo "Usage: track insert <label> <start_time> <end_time>" 1>&2
        exit 1
    fi
    if ! [[ $2 =~ ^[0-9]+$ ]]; then
        echo "Argument start_time has to be a nonnegative integer (unix time)"
        exit 1
    fi
    if ! [[ $3 =~ ^[0-9]+$ ]]; then
        echo "Argument end_time has to be a nonnegative integer (unix time)"
        exit 1
    fi
    if ! (( $2 <= $3 )); then
        echo "The start_time should be no earlier than the end_time"
        exit 1
    fi

    now=$(now)
    dir=$datadir/$1
    filename=$dir/$now

    mkdir -p $dir
    mkdir -p $tmpdir

    echo $2 > $filename
    echo $3 >> $filename

    if [[ git_initialized ]]; then
        git -C $datadir add $filename
        git -C $datadir commit -m "Insert $1"
    fi
}

if [[ "$#" -lt 1 ]]; then
    echo "Timetrack history"
    tree $datadir | tail -n +2
    exit
fi

case "$1" in
    "init")
        init ${@:2}
        ;;
    "start")
        start ${@:2}
        ;;
    "stop")
        stop ${@:2}
        ;;
    "status")
        status ${@:2}
        ;;
    "git")
        run_git ${@:2}
        ;;
    "summarize")
        summarize ${@:2}
        ;;
    "list")
        list ${@:2}
        ;;
    "remove")
        remove ${@:2}
        ;;
    "insert")
        insert ${@:2}
        ;;
    *)
        echo "Command not recognized"
        exit 1
        ;;
esac
