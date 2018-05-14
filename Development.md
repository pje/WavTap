### Build

The build is intended to be as independent of XCode as humanly possible.

`make install` builds and installs both the App and Driver (i.e. everything).

All the needed build operations are defined in the [App](App/Makefile) and [Driver](Driver/Makefile) Makefiles.

(If you're at all comfortable with the command line, use this method instead of the pkg installer.)

### Releases

WavTap's installer is distributed via [Github Releases](https://github.com/pje/WavTap/releases/new).

Grab PackageMaker.app from the [Auxiliary Tools for XCode (Late July 2012)](http://adcdownload.apple.com/Developer_Tools/auxiliary_tools_for_xcode__late_july_2012/xcode44auxtools6938114a.dmg)

Build the `pkg` bundler with PackageMaker.app, using Installer/WavTap.pmdoc

### Versioning

Strictly SemVer, obvi.

App package identifier: `com.wavtap.app.WavTap`
Driver package identifier: `com.wavtap.driver.WavTap`
