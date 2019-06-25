#!/bin/bash
# set -x

SUDO=sudo
# SUDO='echo # sudo'
#SUDO=nothing
CP=cp
# CP='echo # cp'

# certain kexts are exceptions to automatic installation
STANDARD_EXCEPTIONS="Sensors|dspci|WhateverName|TSCAdjustReset|XHCI"
if [[ "$EXCEPTIONS" == "" ]]; then
    EXCEPTIONS="$STANDARD_EXCEPTIONS"
else
    EXCEPTIONS="$STANDARD_EXCEPTIONS|$EXCEPTIONS"
fi

# standard essential kexts
# these kexts are only updated if installed
ESSENTIAL="FakeSMC.kext IntelMausiEthernet.kext Lilu.kext WhateverGreen.kext $ESSENTIAL"

# kexts we used to use, but no longer use
DEPRECATED=" $DEPRECATED"

TAGCMD="$(dirname ${BASH_SOURCE[0]})"/tag
TAG=tag_file
SLE=/System/Library/Extensions
LE=/Library/Extensions

# extract minor version (eg. 10.9 vs. 10.10 vs. 10.11)
MINOR_VER=$([[ "$(sw_vers -productVersion)" =~ [0-9]+\.([0-9]+) ]] && echo ${BASH_REMATCH[1]})

# load colors
source "$(dirname ${BASH_SOURCE[0]})"/colors.sh
activate_colors


# install to /Library/Extensions for 10.11 or greater
if [[ $MINOR_VER -ge 11 ]]; then
    KEXTDEST=$LE
else
    KEXTDEST=$SLE
fi

# this could be removed if 'tag' can be made to work on old systems
function tag_file
{
    if [[ $MINOR_VER -ge 9 ]]; then
        $SUDO "$TAGCMD" "$@"
    fi
}

function check_directory
{
    for x in $1; do
        if [ -e "$x" ]; then
            return 1
        else
            return 0
        fi
    done
}

function nothing
{
    :
}

function remove_kext
{
    $SUDO rm -Rf $SLE/"$1" $LE/"$1"
}

function install_kext
{
    if [ "$1" != "" ]; then
        echo "${BLUE}==>${RESET} installing $1 to $KEXTDEST"
        remove_kext "$(basename $1)"
        $SUDO $CP -Rf $1 $KEXTDEST
        $TAG -a Gray $KEXTDEST/"$(basename $1)"
    fi
}

function install_app
{
    if [ "$1" != "" ]; then
        echo "${BLUE}==>${RESET} installing $1 to /Applications"
        $SUDO rm -Rf /Applications/"$(basename $1)"
        $CP -Rf $1 /Applications
        $TAG -a Gray /Applications/"$(basename $1)"
    fi
}

function install_binary
{
    if [ "$1" != "" ]; then
        if [[ ! -e /usr/local/bin ]]; then $SUDO mkdir /usr/local/bin; fi
        echo "${BLUE}==>${RESET} installing $1 to /usr/local/bin"
        $SUDO rm -f /usr/bin/"$(basename $1)" /usr/local/bin/"$(basename $1)"
        $SUDO $CP -f $1 /usr/local/bin
        $TAG -a Gray /usr/local/bin/"$(basename $1)"
    fi
}

function install
{
    local installed=0
    out=${1/.zip/}
    rm -Rf $out/* && unzip -q -d $out $1
    check_directory $out/Release/*.kext
    if [ $? -ne 0 ]; then
        for kext in $out/Release/*.kext; do
            # install the kext when it exists regardless of filter
            kextname="$(basename $kext)"

            if [[ -e "$SLE/$kextname" || -e "$KEXTDEST/$kextname" || "$2" == "" || "$(echo $kextname | grep -vE "$2")" != "" ]]; then
                install_kext $kext
            fi
        done
        installed=1
    fi
    check_directory $out/*.kext
    if [ $? -ne 0 ]; then
        for kext in $out/*.kext; do
            # install the kext when it exists regardless of filter
            kextname="$(basename $kext)"
            if [[ -e "$SLE/$kextname" || -e "$KEXTDEST/$kextname" || "$2" == "" || "$(echo $kextname | grep -vE "$2")" != "" ]]; then
                install_kext $kext
            fi
        done
        installed=1
    fi
    check_directory $out/Release/*.app
    if [ $? -ne 0 ]; then
        for app in $out/Release/*.app; do
            # install the app when it exists regardless of filter
            appname="$(basename $app)"
            if [[ -e "/Applications/$appname" || -e "/Applications/$appname" || "$2" == "" || "$(echo $appname | grep -vE "$2")" != "" ]]; then
                install_app $app
            fi
        done
        installed=1
    fi
    check_directory $out/*.app
    if [ $? -ne 0 ]; then
        for app in $out/*.app; do
            # install the app when it exists regardless of filter
            appname="$(basename $app)"
            if [[ -e "/Applications/$appname" || -e "/Applications/$appname" || "$2" == "" || "$(echo $appname | grep -vE "$2")" != "" ]]; then
                install_app $app
            fi
        done
        installed=1
    fi
    if [ $installed -eq 0 ]; then
        check_directory $out/*
        if [ $? -ne 0 ]; then
            for tool in $out/*; do
                install_binary $tool
            done
        fi
    fi
}

function warn_about_superuser
{
    if [ "$(id -u)" != "0" ]; then
        sudo -p "This script requires superuser access... " printf "%s\r" ""
    fi
}

function install_download_tools
{
    # unzip/install tools
    check_directory downloads/tools/*.zip
    if [ $? -ne 0 ]; then
        echo "${GREEN}==>${RESET} installing tools..."
        for tool in downloads/tools/*.zip; do
            install $tool
        done
        echo
    fi
}

function install_download_kexts
{
    # unzip/install kexts
    check_directory downloads/kexts/*.zip
    if [ $? -ne 0 ]; then
        echo "${GREEN}==>${RESET} installing kexts..."
        for kext in downloads/kexts/*.zip; do
            install $kext "$EXCEPTIONS"
        done
        echo
    fi
}

function install_brcmpatchram_kexts
{
    if [[ $MINOR_VER -ge 11 ]]; then
        # 10.11 needs BrcmPatchRAM2.kext
        install_kext downloads/kexts/RehabMan-BrcmPatchRAM*/Release/BrcmPatchRAM2.kext
        install_kext downloads/kexts/RehabMan-BrcmPatchRAM*/Release/BrcmNonPatchRAM2.kext
        # remove BrcPatchRAM.kext/etc just in case
        remove_kext BrcmPatchRAM.kext
        remove_kext BrcmNonPatchRAM.kext
    else
        # prior to 10.11, need BrcmPatchRAM.kext
        install_kext downloads/kexts/RehabMan-BrcmPatchRAM*/Release/BrcmPatchRAM.kext
        install_kext downloads/kexts/RehabMan-BrcmPatchRAM*/Release/BrcmNonPatchRAM.kext
        # remove BrcPatchRAM2.kext/etc just in case
        remove_kext BrcmPatchRAM2.kext
        remove_kext BrcmNonPatchRAM2.kext
    fi
    # this guide does not use BrcmBluetoothInjector.kext/BrcmFirmwareData.kext
    remove_kext BrcmBluetoothInjector.kext
    remove_kext BrcmFirmwareData.kext
}

function remove_deprecated_kexts
{
    for kext in $DEPRECATED; do
        remove_kext $kext
    done
}

function install_fakesmc_sensor_kexts
{
    for kext in downloads/kexts/RehabMan-FakeSMC*/FakeSMC_*Sensors.kext;
    do
        install_kext "$kext"
    done
}

function _create_and_install_lilufriend
# $1 optional, template kext to use (default is LiluFriendTemplate.kext)
# $2 optional, output kext name (default is LiluFriend.kext)
{
    local template="$(dirname ${BASH_SOURCE[0]})"/template_kexts/LiluFriendTemplate.kext
    if [[ "$1" != "" ]]; then template="$1"; fi
    local output="LiluFriend.kext"
    if [[ "$2" != "" ]]; then template="$2"; fi
    "$(dirname ${BASH_SOURCE[0]})"/create_lilufriend.sh "$1" "$2"
    install_kext "$2"
}

function create_and_install_lilufriend
{
    _create_and_install_lilufriend "$(dirname ${BASH_SOURCE[0]})"/template_kexts/LiluFriendTemplate.kext LiluFriend.kext
}

function create_and_install_lilufriendlite
{
    _create_and_install_lilufriend "$(dirname ${BASH_SOURCE[0]})"/template_kexts/LiluFriendLiteTemplate.kext LiluFriendLite.kext
}

function rebuild_kernel_cache
{
    echo "${BLUE}==>${RESET} rebuilding kextcache..."
    # force cache rebuild with output
    $SUDO touch $SLE && $SUDO kextcache -u /
}

function finish_kexts
{
    echo "${GREEN}==>${RESET} create LiluFriend kext..."
    # rebuild cache before making LiluFriend
    remove_kext LiluFriendLite.kext
    remove_kext LiluFriend.kext
    rebuild_kernel_cache

    # create LiluFriend (not currently using LiluFriendLite) and install
    create_and_install_lilufriend
    echo

    # all kexts are now installed, so rebuild cache again
    echo "${GREEN}==>${RESET} all kexts are now installed, so rebuild cache again..."
    rebuild_kernel_cache
}

function update_efi_kexts
{
    # install/update kexts on EFI/Clover/kexts/Other
    local EFI=$("$(dirname ${BASH_SOURCE[0]})"/mount_efi.sh)
    echo Updating kexts at EFI/Clover/kexts/Other
    for kext in $ESSENTIAL; do
        if [[ -e $KEXTDEST/$kext ]]; then
            echo updating "$EFI"/EFI/CLOVER/kexts/Other/$kext
            $CP -Rfp $KEXTDEST/$kext "$EFI"/EFI/CLOVER/kexts/Other
        fi
    done
    # remove deprecated kexts from EFI that were typically ESSENTIAL
    for kext in $DEPRECATED; do
        if [[ ! -e $KEXTDEST/$kext && -e "$EFI"/EFI/CLOVER/kexts/Other/$kext ]]; then
            echo removing "$EFI"/EFI/CLOVER/kexts/Other/$kext
            rm -Rf "$EFI"/EFI/CLOVER/kexts/Other/$kext
        fi
    done
}

function install_tscadjustreset
{
    echo "${GREEN}==>${RESET} create TSCAdjustReset kext..."
    "$(dirname ${BASH_SOURCE[0]})"/create_tscadjustreset.sh downloads/kexts/*TSCAdjustReset/TSCAdjustReset.kext/Contents/Info.plist
    install_kext downloads/kexts/*TSCAdjustReset/TSCAdjustReset.kext
    echo
}

function install_xhc
{
    echo "${GREEN}==>${RESET} choose XHCI kext..."

    cd downloads/kexts/kgp-XHC_USB_truncated/ || exit 1
    for w in *.kext
    do
        options=("$w" "${options[@]}")
    done
    cd ../../.. || exit 1

    prompt="Please select your motherboard:"
    PS3="$prompt "
    select xhci_kext in "${options[@]}" "Quit" ; do
        if (( REPLY == 1 + ${#options[@]} )) ; then
            exit

        elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
            break

        else
            echo "Invalid option. Try another one."
        fi
    done

    install_kext downloads/kexts/kgp-XHC_USB_truncated/"$xhci_kext"

    echo
}

#EOF
