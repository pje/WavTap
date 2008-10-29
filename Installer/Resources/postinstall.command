#!/usr/bin/perl

# -- Touch the /System/Library/Extensions dir, and load our kext

system("echo 'kext postinstall script-----'");
system("sudo kextload /System/Library/Extensions/Soundflower.kext");
system("sudo touch /System/Library/Extensions");

exit(0);
