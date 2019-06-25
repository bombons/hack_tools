#!/bin/bash
#set -x

# load colors
source "$(dirname ${BASH_SOURCE[0]})"/colors.sh
activate_colors

plbuddy="/usr/libexec/PlistBuddy"
# plbuddy='echo # PlistBuddy'

function get_plist_property
# $1 plist path
# $2 property path
{
    local property=$($plbuddy -c "Print $2" "$1" 2>&1)
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
    $plbuddy -c "Delete $2" "$1" >/dev/null 2>&1
}

function set_plist_string_property
# $1 plist path
# $2 property path
# $3 property value
{
    delete_plist_property "$1" "$2"
    $plbuddy -c "Add '$2' string" "$1"
    $plbuddy -c "Set '$2' '$3'" "$1"
}

set_plist_string_property "$1" ":IOKitPersonalities:TSCAdjustReset:IOPropertyMatch:IOCPUNumber" "$(($(sysctl -n hw.ncpu)-1))"
