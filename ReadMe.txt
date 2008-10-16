Soundflower Source ReadMe
(revised 16 October 2008 for version 1.4)

Originally by ma++ ingalls
   for Cycling'74
matt@sfsound.org



PROJECT CONFIGURATION

Soundflower.xcodeproj is an Xcode 3.1 compatible project.

There are two Build Configurations in the project: the Development build configuration builds Soundflower for the architecture of the machine you are using suitable for debugging. The Deployment configuration builds a Universal Binary version suitable for distribution.  Both configurations link against the Mac OS 10.4 SDK.



PERMISSIONS

Files in a kernel extension (kext) bundle have to be set as follows:
	owner: root - read/write
	group: wheel - read only
	others: read only

Unfortunately there doesn't seem to be a simple way to do this in Xcode. We tried running the xcodebuild command-line tool as root, but it sets the group to "admin" not "wheel" and OS X requires that the kernel extension group be set to wheel.

One solution for setting owner and group properly is to rebuild Soundflower using Xcode, then build a new installer by double-clicking the Soundflower.pmproj file to launch PackageMaker. This project is set up to look for a Soundflower.kext file in the folder Actual Item, which is where the Xcode project builds it.

However, before building the installer, you need to change the permissions on the kext bundle:

- Open the Soundflower.pmproj file in PackageMaker

- Click the Contents tab

- Click the File Permissions... button

- Click the Apply Recommendations button (you'll then need to enter a root password after you click OK)

This changes the owner / group to root / wheel as is necessary. We've seen cases where Apply Recommendations did not do the right thing so check the resulting permissions against the requirements listed above.

At this point, you could install the Soundflower.kext bundle inside the Actual item folder manually, or you could choose Build... from the Project menu in PackageMaker to create a new Soundflower.pkg file. Then run the installer you created and enter a root password.

The PackageMaker project uses relative paths to find its files, so the Actual Item and Resources folders should remain where they are relative to the .pmproj file.

Note that after you change the permissions of Soundflower.kext to root/wheel in the Actual Item folder, attempting to rebuild or even Clean the Soundflower.xcodeproj in Xcode will fail. If you want to rebuild the kernel extension from scratch after having changed the owner and group, first delete Soundflower.kext from the Actual Item folder manually in the Finder.

Please feel free to contact me if you have any questions!


