## WavTap

Capture whatever your mac is playing to a .wav file on your Desktop—as simply as a screenshot.

![](screenshot.png)

(This is alpha software. It will cause your computer to catch fire. 🔥)

#### Installation

##### Sierra
It's alive! Takes a few additional steps but unsigned kexts can be run if you complete the following steps.

1. Restart computer in recovery mode ```⌘R```

2. In Terminal type

   ```csrutil disable```

3. Restart computer

4. Run Installer

##### El Capitan 

**NB: WavTap is completely broken on El Capitan** due to Apple's [System Integrity Protection] (https://en.wikipedia.org/wiki/System_Integrity_Protection). The next release of WavTap will fix this.

##### Yosemite

As of Yosemite, Apple bans drivers that haven't received explicit approval from Apple. The only workaround I'm aware of is to set a system flag to [globally allow **all** unsigned kernel extensions](http://apple.stackexchange.com/questions/163059/how-can-i-disable-kext-signing-in-mac-os-x-10-10-yosemite). This means WavTap *will not work* unless you've enabled `kext-dev-mode`, using something like this:

```shell
sudo nvram boot-args=kext-dev-mode=1
```

Yes, [this sucks](https://www.gnu.org/philosophy/can-you-trust.html).

Once that's done, run the [installer](https://github.com/pje/WavTap/releases/download/0.3.0/WavTap.0.3.0.pkg).

#### Uninstallation

`make uninstall` removes everything

##### Nerd Corner

WavTap began as a fork of [Soundflower](https://github.com/Cycling74/Soundflower). thanks to [Cycling '74](http://cycling74.com), [tap](http://github.com/tap), [ma++ ingalls](http://sfsound.org/matt.html), and everyone else who's contributed to it.
