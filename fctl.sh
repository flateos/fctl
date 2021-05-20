#! /bin/bash

# Copyright (c) 2021 Romullo @hiukky.

# This file is part of FlateOS
# (see https://github.com/flateos).

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

set -eE

declare cmd=$1
declare flag=$2
declare args="${@:3}"

function help() {
    cat <<EOM
Usage: fctl [command] [options]

  workspace             Workspace manager for sway.
  system                Obtain system-related information.
  record                Video and audio recording.
  print                 Print Screen.
  theme                 Theme Manager.

EOM
}

function workspace() {
    case $flag in
    '-s'|'--set')
        swaymsg workspace $args;;

    '-c'|'--current')
        swaymsg -t get_outputs | jq '.[] | .current_workspace' | sed 's/"//g';;

    *)
        help;;
    esac
}

function system() {
    case $flag in
    '-m'|'--memory')
        printf "%.0f\n" $(free -m | grep Mem | awk '{print ($3/$2)*100}');;

    '-c'|'--cpu')
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}';;

    '-d'|'--disk')
        df --output=pcent / | grep -E -o "[0-9]+";;

    '-h'|'--host')
        echo "$(whoami)@$(hostname)";;

    '-n'|'--net')
        local STATS=`ping -c2 8.8.8.8 | grep 'received' | awk -F',' '{ print $2}' | awk '{ print $1}'`

        [[ $STATS -eq 2 ]] && echo connected || not-connected;;

    *)
        help;;
    esac
}

function print() {
    local OUTPUT="$HOME/Pictures/Screenshots"
    local FILE_NAME="screenshot-$(date +"%d-%m-%Y %H:%M:%S").png"

    [[ ! -d $OUTPUT ]] && mkdir -p $OUTPUT

    case $flag in
    '-a'|'--area')
        grim -g "$(
            swaymsg -t get_tree \
                | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' \
                | slurp -o
        )" "$OUTPUT/$FILE_NAME"

        [[ ! ($? -eq 0) ]] && exit

        notify-send "Screenshot saved to: $OUTPUT/$FILE_NAME"
    ;;

    *)
        help;;
    esac
}

function theme() {
    case $flag in
    '-c'|'--color')
        f=3 b=4

        for j in f b; do
            for i in {0..7}; do
                printf -v $j$i %b "\e[${!j}${i}m"
            done
        done

        d=$'\e[1m'
        t=$'\e[0m'
        v=$'\e[7m'


cat << EOF
$f0████$d▄$t  $f1████$d▄$t  $f2████$d▄$t  $f3████$d▄$t  $f4████$d▄$t  $f5████$d▄$t  $f6████$d▄$t  $f7████$d▄$t
$f0████$d█$t  $f1████$d█$t  $f2████$d█$t  $f3████$d█$t  $f4████$d█$t  $f5████$d█$t  $f6████$d█$t  $f7████$d█$t
$f0████$d█$t  $f1████$d█$t  $f2████$d█$t  $f3████$d█$t  $f4████$d█$t  $f5████$d█$t  $f6████$d█$t  $f7████$d█$t
$d$f0 ▀▀▀▀  $d$f1 ▀▀▀▀   $f2▀▀▀▀   $f3▀▀▀▀   $f4▀▀▀▀   $f5▀▀▀▀   $f6▀▀▀▀   $f7▀▀▀▀$t
EOF
    ;;

    *)
        help;;
    esac
}

function record() {
    case $flag in
    '-s'|'--screen')
        local OUTPUT=$HOME/Videos
        local FILE_NAME="video-$(date +"%d-%m-%Y:%H:%M:%S").mp4"

        [[ ! -d $OUTPUT ]] && mkdir -p $OUTPUT

        if [[ -z "$(pgrep wf-recorder)" ]]; then
            notify-send "Recording"
            wf-recorder -a --file=$OUTPUT/$FILE_NAME
        else
            notify-send "Recording saved to: $OUTPUT/$FILE_NAME"
            pkill --signal SIGINT wf-recorder
        fi
    ;;

    '-st'|'--screen-state')
        [[ -n "$(pgrep wf-recorder)" ]] && echo recording || echo stopped
    ;;

    *)
        help;;
    esac
}

function main() {
    case $cmd in
    'workspace')
        workspace;;
    'system')
        system;;
    'record')
        record;;
    'print')
        print;;
    'theme')
        theme;;
    *)
        help;;
    esac
}

main
