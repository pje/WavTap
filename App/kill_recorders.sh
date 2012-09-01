#!/usr/bin/env bash

recorder_process='/Applications/WavTap.app/Contents/SharedSupport/sox'
ps -axo pid,command,args | grep $recorder_process | grep -v grep | awk '{ print $1 }' | kill -SIGINT
