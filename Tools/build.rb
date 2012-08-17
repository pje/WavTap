#!/usr/bin/env ruby -wKU

###################################################################
# build Soundflower, install it, and start it
# installs to /System/Library/Extensions
# requires admin permissions and will ask for your password
###################################################################

require 'open3'
require 'fileutils'
require 'pathname'
require 'rexml/document'
include REXML

# This finds our current directory, to generate an absolute path for the require
libdir = "."
Dir.chdir libdir        # change to libdir so that requires work

if(ARGV.length > 1)
  puts "usage: "
  puts "build.rb [configuration (Development|Deployment)]"
  exit 0;
end

configuration = ARGV[0] || "Development"
configuration = "Development" if configuration == "dev"
configuration = "Deployment" if configuration == "dep"

@project_root = ".."
@source = "#{@project_root}/Source"
@source_sfb = "#{@project_root}/SoundflowerBed"

###################################################################

puts "  Building the new Soundflower.kext with Xcode"

Dir.chdir("#{@source}")
Open3.popen3("xcodebuild -project Soundflower.xcodeproj -target SoundflowerDriver -configuration #{configuration} clean build") do |stdin, stdout, stderr|
  if /BUILD SUCCEEDED/.match(stdout.read)
    puts "    BUILD SUCCEEDED"
  else
    puts "    BUILD FAILED"
    puts "      #{stderr.read}"
  end
end

###################################################################

puts "  Building the new Soundflowerbed.app with Xcode"

Dir.chdir("#{@source_sfb}")
Open3.popen3("xcodebuild -project Soundflowerbed.xcodeproj -target Soundflowerbed -configuration #{configuration} clean build") do |stdin, stdout, stderr|
  if /BUILD SUCCEEDED/.match(stdout.read)
    puts "    BUILD SUCCEEDED"
  else
    puts "    BUILD FAILED"
    puts "      #{stderr.read}"
  end
end

###################################################################

puts "  Done."
puts ""
exit 0
