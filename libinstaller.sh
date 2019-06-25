#!/usr/bin/env bash

# set -x

PLBUDDY="/usr/libexec/PlistBuddy"
# PLBUDDY='echo # /usr/libexec/PlistBuddy'


function download
# $1 url
# $2 output file name (optional, otherwise uses remote name)
# $3 mode
{
    local url="$1"
    echo "downloading $(basename $1):"

    if [[ "$3" == 'silent' ]]; then
        curl_options="--retry 5 --location --silent"
    else
        curl_options="--retry 5 --location --progress-bar"
        echo $url
    fi

    if [ "$2" == "" ]; then
        curl $curl_options --remote-name "$url"
    else
        curl $curl_options --output "$2" "$url"
    fi

    if [[ "$3" != 'silent' ]]; then
        echo
    fi

}

function get_plist_property
# $1 plist path
# $2 property path
{
    local property=$($PLBUDDY -c "Print $2" "$1" 2>&1)
    if [[ "$property" == *"Does Not Exist"* ]]; then
        echo "__property_not_found__"
    else
        echo "$property"
    fi
}

function delete_plist_property
# $1 plist path
# $2 property path
{
    $PLBUDDY -c "Delete $2" "$1" >/dev/null 2>&1
}

function set_plist_string_property
# $1 plist path
# $2 property path
# $3 property value
{
    delete_plist_property "$1" "$2"
    $PLBUDDY -c "Add '$2' string" "$1"
    $PLBUDDY -c "Set '$2' '$3'" "$1"
}


function plutil_convert
# $1 plist file
{
    plutil -convert xml1 "$1"
}

function plutil_check
# $1 plist file
{
    plutil -lint "$1"
}

function plutil_extract
# $1 path separetor is dot
# $2 plist file
# $3 output file
{
    plutil -extract "$1" xml1 -o - "$2" > "$3"
}

function plutil_get_value
# $1 path, separetor is dot
# $2 plist file
{
    local property=$(plutil -extract "$1" xml1 -o - "$2" 2>&1)
    if [[ "$property" == *"Could not extract value"* ]]; then
        echo "__property_not_found__"
    else
        echo "$property"
    fi
}

read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
    local RET=$?
    TAG_NAME=${ENTITY%% *}
    ATTRIBUTES=${ENTITY#* }
    return $RET
}

parse_dom () {
    if [[ $TAG_NAME = "string" ]] ; then
        eval local $ATTRIBUTES
        echo "$CONTENT"
    fi
}

function count_plist_array_elements
# $1 array key
# $2 plist file
{
    PLISTBUDDY="$PLBUDDY -c"
    if [ "$#" -ne 2 ]; then
        echo "usage: $0 <array key> <plistfile>"
        exit 1
    fi
    KEY=$1
    PLIST=$2
    i=0
    while true ; do
        $PLISTBUDDY "Print :$KEY:$i" "$PLIST" >/dev/null 2>/dev/null
        if [ $? -ne 0 ]; then
            echo $i
            break
        fi
        i=$(($i + 1))
    done
}
