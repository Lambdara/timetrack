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
    if [[ -d $datadir ]]; then
        echo "Already initialized"
        exit 1
    fi

    mkdir $datadir
}

function now {
    echo "$(date +%s)"
}

function start {
    now=$(now)
    dir=$datadir/$1
    filename=$dir/$now

    mkdir -p $dir
    mkdir -p $tmpdir

    echo $now > $filename
    tmpfile=$tmpdir/$(cat /dev/urandom | tr -cd 'a-z0-9' | head -c 32)
    ln -s $filename $tmpfile
}

function stop {
    now=$(now)

    for file in $tmpdir/*; do
        echo $now >> $file
        rm $file
    done
}

function summarize {
    total=0
    for file in $(find $datadir/$1 -type f); do
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
    "tree")
        tree $datadir
        ;;
    "git")
        echo "TODO: git"
        ;;
    "summarize")
        summarize ${@:2}
        ;;
    *)
        echo "Command not recognized"
        exit 1
        ;;
esac