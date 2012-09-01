#!/usr/bin/env bash

format=wav
output_file=~/Desktop/`date +%s`.$format

if [[ -n "$1" ]]; then
	bits="--bits $1"
else
	bits=""
fi

recorder_process='/Applications/WavTap.app/Contents/SharedSupport/sox'
pid=`ps -axo pid,command,args | grep $recorder_process | grep -v grep | awk '{ print $1 }'`

if [[ -z $pid ]]; then
  /Applications/WavTap.app/Contents/SharedSupport/sox -V6 -t coreaudio 'WavTap (2ch)' $bits $output_file
fi
