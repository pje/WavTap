## WavTap

capture whatever your mac is playing to an audio file

`^⌘Space` starts/stops recording

#### Installation

`make install`

select WavTap as the system audio output device within Audio Midi Setup

click on the WavTap icon in the menubar and select Built-in Output

notes:
- for now it's only buildable from source
- i've only tested this with Xcode 4.4.1
- it absolutely requires the AppleCommandLineTools thing
- you'll need admin privileges for the make step (since it's installing a kernel extension)
  - but no restart!
- to uninstall, run `make uninstall`

#### Nerd Corner

the default shortcut is editable via SystemPreferences -> Keyboard -> Services -> General -> WavTap

it's a fork — but lives independently of — [Soundflower](https://github.com/tap/Soundflower)—thanks to [ma++ ingalls](http://sfsound.org/matt.html), [Cycling '74](http://cycling74.com), [tap](http://github/tap), and everyone else who's contributed to it.

ɔ [GNU GPL](http://www.gnu.org/copyleft/gpl.html)
