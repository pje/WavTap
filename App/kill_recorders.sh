#!/usr/bin/env bash

recorder_process='WavTap.app/Contents/SharedSupport/sox'
ps -axo pid,command,args | grep $recorder_process | grep -v grep | awk '{ print $1 }' | xargs kill -s SIGINT
