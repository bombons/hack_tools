#!/bin/bash

# set -x

curl_options="--retry 5 --location --progress-bar"
curl_options_silent="--retry 5 --location --silent"

# download from bitbucket downloads
function download_bitbucket
# $1 is account name on bitbucket
# $2 is subdir on account bitbucket
# $3 is prefix of zip file name
# $4 is output file name (optional, otherwise uses remote name)
{
    echo "downloading $3:"
    curl $curl_options_silent --output /tmp/org.rehabman.download.txt https://bitbucket.org/$1/$2/downloads/
    local scrape=$(grep -o -m 1 "/RehabMan/$2/downloads/$3.*\.zip" /tmp/org.rehabman.download.txt | perl -ne 'print $1 if /(.*)\"/')
    local url=https://bitbucket.org$scrape
    echo $url
    if [ "$4" == "" ]; then
        curl $curl_options --remote-name "$url"
    else
        curl $curl_options --output "$4" "$url"
    fi
    echo
}

# download typical release from RehabMan bitbucket downloads
function download_rehabman
# $1 is subdir on rehabman bitbucket
# $2 is prefix of zip file name
# $3 is output file name (optional, otherwise uses remote name)
{
    download_bitbucket "RehabMan" "$1" "$2" "$3"
}

# download latest release from github (perhaps others)
function download_latest_notbitbucket
# $1 is main URL
# $2 is URL of release page
# $3 is partial file name to look for
# $4 is output file name (not optional)
{
    echo "downloading $4:"
    curl $curl_options_silent --output /tmp/org.rehabman.download.txt "$2"
    local scrape=$(grep -o -m 1 "/.*$3.*\.zip" /tmp/org.rehabman.download.txt)
    local url=$1$scrape
    echo $url
    curl $curl_options --output "$4" "$url"
    echo
}

# download from acidanthera project on github
function download_acidanthera
# $1 is name of acidanthera project on github
# $2 is basename of output zip
{
    download_latest_notbitbucket "https://github.com" "https://github.com/acidanthera/$1/releases" "RELEASE" "$2.zip"
}

# download from bombons project on github
function download_bombons
# $1 is name of bombons project on github
# $2 is partial file name to look for
# $3 is basename of output zip
{
    download_latest_notbitbucket "https://github.com" "https://github.com/bombons/$1/releases" "$2" "$3.zip"
}

# download from bitbucket downloads
function download_bitbucket_bombons
# $1 is subdir on account bitbucket
# $2 is prefix of zip file name
# $3 is output file name (optional, otherwise uses remote name)
{
    echo "downloading $2:"
    curl $curl_options_silent --output /tmp/org.bombons.download.txt https://bitbucket.org/bombons/$1/downloads/
    local scrape=$(grep -o -m 1 "/bombons/$1/downloads/$2.*\.zip" /tmp/org.bombons.download.txt | perl -ne 'print $1 if /(.*)\"/')
    local url=https://bitbucket.org$scrape
    echo $url
    if [ "$3" == "" ]; then
        curl $curl_options --remote-name "$url"
    else
        curl $curl_options --output "$3" "$url"
    fi
    echo
}

function download_cloverconfig() {
    echo "downloading $1:"
    local url='https://mackie100projects.altervista.org/apps/cloverconf/download-new-build.php?version=global'
    echo $url
    if [ "$2" == "" ]; then
        curl $curl_options --remote-name "$url"
    else
        curl $curl_options --output "$2" "$url"
    fi
    echo
}

function download_raw() {
    local file="$(basename $1)"
    local file="${file%.*}"

    echo "downloading $file:"
    local url="$1"
    echo $url
    if [ "$2" == "" ]; then
        curl $curl_options --remote-name "$url"
    else
        curl $curl_options --output "$2" "$url"
    fi
    echo
}
