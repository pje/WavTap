#!/usr/bin/env bash

defaults write pbs NSServicesStatus -dict-add '"(null) - WavTap - runWorkflowAsService"' '{ "key_equivalent" = "@^Space"; }'
