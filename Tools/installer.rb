#!/usr/bin/env ruby -wKU

###################################################################
# make an installer for Soundflower
# requires: you must have already performed a Deployment build and
#           that the kext is installed to /System/Library/Extensions
###################################################################

require 'open3'
require 'fileutils'
require 'pathname'
require 'rexml/document'
include REXML

# This finds our current directory, to generate an absolute path for the require
libdir = "."
Dir.chdir libdir        # change to libdir so that requires work

@svn_root = ".."
@temp = "#{@svn_root}/Installer/temp"
#@max = "#{@temp}/Applications/MaxMSP\ 4.6"
#@c74 = "#{@max}/Cycling '74"

@version = "1.3.5"


###################################################################
# sub routines
###################################################################

def create_logs
  @build_log = File.new("#{@svn_root}/Installer/_installer.log", "w")
  @build_log.write("SOUNDFLOWER INSTALLER LOG: #{`date`}\n\n")
  @build_log.flush
  @error_log = File.new("#{@svn_root}/Installer/_error.log", "w")
  @error_log.write("SOUNDFLOWER INSTALLER ERROR LOG: #{`date`}\n\n")
  @error_log.flush
  trap("SIGINT") { die }
end
  
def die
  close_logs
  exit 0
end

def close_logs
  @build_log.close
  @error_log.close
end

def log_build(str)
  @build_log.write(str)
  @build_log.write("\n\n")
  @build_log.flush
end

def log_error(str)
  @error_log.write(str)
  @error_log.write("\n\n")
  @error_log.flush
end


# This defines a wrapper that we use to call shell commands
def cmd(commandString)
  out = ""
  err = ""
  
  Open3.popen3(commandString) do |stdin, stdout, stderr|
    out = stdout.read
    err = stderr.read
  end
  log_error(out)
  log_error(err)
end


###################################################################
# here is where we actually build the installer
###################################################################

create_logs()

puts "  Creating installer directory structure..."
cmd("rm -rfv \"#{@temp}\"")                                         # remove an old temp dir if it exists
cmd("mkdir -pv \"#{@temp}\"")                                       # now make a clean one, and build dir structure in it
cmd("mkdir -pv \"#{@temp}/System/Library/Extensions\"")

puts "  Copying the built kext..."
cmd("cp -rpv \"#{@svn_root}/Build/Soundflower.kext\" \"#{@temp}/System/Library/Extensions\"")

puts "  Copying readme, license, etc...."
cmd("cp \"#{@svn_root}/Jamoma/ReadMe.rtf\" \"#{@svn_root}/Installers/resources\"")
cmd("cp \"#{@svn_root}/Jamoma/ReadMe.rtf\" \"#{@svn_root}/Installers/Jamoma\"")
cmd("cp \"#{@svn_root}/Jamoma/GNU-LGPL.rtf\" \"#{@svn_root}/Installers/resources/License.rtf\"")
cmd("cp \"#{@svn_root}/Jamoma/GNU-LGPL.rtf\" \"#{@svn_root}/Installers/Jamoma/License.rtf\"")

puts "  Building Package -- this could take a while..."
cmd("rm -rfv \"#{@svn_root}/Installers/MacInstaller/Jamoma.pkg\"")
cmd("/Developer/usr/bin/packagemaker --verbose --root \"#{@svn_root}/Installers/temp\" --id org.jamoma.jamoma --out \"#{@svn_root}/Installers/Jamoma/Jamoma.pkg\" --version #{@version} --title Jamoma --resources \"#{@svn_root}/Installers/resources\" --target 10.4 --domain system --root-volume-only")

# Warning: the zip thing seems to be a real problem on the Mac using OS 10.5 at least...  Renaming the zip ends up causing the install to fail
#puts "  Zipping the Installer..."
#cmd("rm -rfv \"#{@svn_root}/Installers/Jamoma-0.4.6.zip\"")
#cmd("zip -rj \"#{@svn_root}/Installers/Jamoma.pkg.zip\" \"#{@svn_root}/Installers/Jamoma.pkg\"")
#cmd("mv \"#{@svn_root}/Installers/Jamoma.pkg.zip\" \"#{@svn_root}/Installers/Jamoma-0.4.6-Mac.pkg.zip\"")

puts "  Creating Disk Image..."
cmd("rm -rfv \"#{@svn_root}/Installers/Jamoma-#{@version}-Mac.dmg\"")
cmd("hdiutil create -srcfolder \"#{@svn_root}/Installers/Jamoma\" \"#{@svn_root}/Installers/Jamoma-#{@version}-Mac.dmg\"")

puts "  All done!"

close_logs
puts ""
exit 0
