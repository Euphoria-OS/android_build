#!/bin/bash

# This script collect build info and sends it to my server
# Copyright (C) 2015 Jacob McSwain
#
# This file is part of BuildAnalytics.
#
# BuildAnalytics is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation.
#
# BuildAnalytics is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with BuildAnalytics. If not, see <http://www.gnu.org/licenses/>.


STARTTIME=$1
ENDTIME=$(date +%s)

PROC_MODEL=$(grep "model name" /proc/cpuinfo | awk -F':' '{print $2}' | head -n 1 | xargs | sed s/@/at/g)
NUMBER_OF_PROCS=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)

DISTRO="Unix-like"

if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO=$DISTRIB_DESCRIPTION
elif [ -f /etc/debian_version ]; then
    DISTRO="Debian $(cat /etc/debian_version)"
elif [ -f /etc/redhat-release ]; then
    DISTRO="Red Hat"
elif [ -f /etc/SUSE-release ]; then
    DISTRO="SUSE"
elif [ -f /etc/fedora-release ]; then
    DISTRO="Fedora"
elif [ -f /etc/slackware-release ]; then
    DISTRO="Slackware"
elif [ -f /etc/mandrake-release ]; then
    DISTRO="Mandrake"
elif [ -f /etc/yellowdog-release ]; then
    DISTRO="Yellow Dog"
elif [ -f /etc/gentoo-release ]; then
    DISTRO="Gentoo"
else
    DISTRO=$(uname -s)
fi

BUILD_USING_CCACHE=$USE_CCACHE
CCACHE_SIZE=$(ccache -s | grep "cache size" | head -1 | awk -F' ' '{print $3 " " $4}')
DISK_INFO=$(lsblk -d -o name,rota)
NUM_DISKS=$(lsblk -d -o name,rota | wc -l)

SSD_DISKS=""
HDD_DISKS=""

COUNTER=2
while [ $COUNTER -lt $((NUM_DISKS+1)) ]; do
            TMPDISKINFO=$(echo "$DISK_INFO" | sed -n "$COUNTER p")
            if [[ "$TMPDISKINFO" == *0 ]]
                then
                    if [ $COUNTER -eq 2 ]
                        then
                          SSD_DISKS=$(echo "$TMPDISKINFO" | awk -F' ' '{print $1}')
                        else
                          SSD_DISKS=$SSD_DISKS:$(echo "$TMPDISKINFO" | awk -F' ' '{print $1}')
                    fi
                else
                    if [ $COUNTER -eq 2 ]
                        then
                          HDD_DISKS=$(echo "$TMPDISKINFO" | awk -F' ' '{print $1}')
                        else
                          HDD_DISKS=$HDD_DISKS:$(echo "$TMPDISKINFO" | awk -F' ' '{print $1}')
                    fi
            fi
            let COUNTER=COUNTER+1
        done

OUT_VOLUME=$(df "$OUT_DIR" | sed -n "2p" | awk -F' ' '{print $1}')
SOURCE_VOLUME=$(df "$INPUT_DIR" | sed -n "2p" | awk -F' ' '{print $1}')

TOTAL_MEMORY=$(free -t -h | sed -n "2p" | awk -F' ' '{print $2}')
PLATFORM=$(python -c "import platform; print(platform.platform())")

BUILD_TIME=$((ENDTIME-STARTTIME))

USING_PREBUILT_CHROMIUM=$PRODUCT_PREBUILT_WEBVIEWCHROMIUM

BASEURL="http://desolationrom.com/regAndroidBuild.php?"
ARGSURL="cpu=$PROC_MODEL&numprocs=$NUMBER_OF_PROCS&distro=$DISTRO&using_ccache=$BUILD_USING_CCACHE&ccache_size=$CCACHE_SIZE&ssds=$SSD_DISKS&hdds=$HDD_DISKS&outvolume=$OUT_VOLUME&sourcevolume=$SOURCE_VOLUME&totalmemory=$TOTAL_MEMORY&platform=$PLATFORM&prebuiltchromium=$USING_PREBUILT_CHROMIUM&buildtime=$BUILD_TIME"
curl "$BASEURL""$ARGSURL"
