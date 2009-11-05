#!/usr/bin/perl

# -- Touch the /System/Library/Extensions dir, and load our kext

system("echo 'kext postinstall script-----'");
system("sudo touch /System/Library/Extensions");
system("sudo kextload /System/Library/Extensions/Soundflower.kext");

exit(0);
