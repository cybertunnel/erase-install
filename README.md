# Erase & Install


![](./readMe_images/icon_512x512.png)


Description 
===================================

**EraseInstall.app** for macOS is designed to allow users to easily erase the HD on their Mac and install a fresh copy of macOS.
The application is a wrapper around the command `startosinstall`. 

This command is included in the 'Install macOS High Sierra/Mojave' application, which you can download in the Mac App Store. The `startosinstall` command can be used to upgrade the current system, or (optionally) to erase the current system and replace it with a fresh installation of macOS.

Please be aware that the **EraseInstall.app** will **Erase your system disk**.  

Requirements
===================================

**EraseInstall** supports the following macOS versions:

* macOS 10.13.0 and higher
* macOS 10.14.0 and higher
* macOS 10.15.0 and higher

_Important:_
Because this new version is built with Swift 5, it will require the [Swift 5 Runtime Support](https://support.apple.com/kb/DL1998) to be installed as well, when on macOS 10.14.3 and older.

Installation
===================================

1. [Download the installer package here.](https://bitbucket.org/prowarehouse-nl/erase-install/downloads/)
2. Install the EraseInstall app using the installer. 

Prerequisites
===================================

1. Running macOS 10.13.0 and later
2. Current system volume is formatted in APFS format.
3. "Install macOS" application (for macOS 10.13.4 and later), needs to be present on the Mac when the EraseInstall application is launched

Using the EraseInstall application
===================================

1. Open the app
2. Follow the steps on screen. 
3. Done. The system on your Mac will be erased and re-installed with the macOS Installer.

Troubleshooting
===================================

You can open a log window with the command-L keyboard shortcut.

The preparation phase can take a few minutes, especially on slow drives. When the process seems to stall indefinitely, the cause is often that the `startosinstall` command has errored out. In this case try running the `startosinstall` command manually from Terminal so you can see a better error message. You can see the exact syntax of the command the EraseInstall application uses in the log window.

The macOS installer does _not_ allow to directly downgrade from 10.14.1+ to 10.13.

Customizing the Installation with Packages
===================================

Starting in version 1.2 you can add custom packages to the erase and install process.

The EraseInstall application will look for package installers (pkg) files in the `/Library/Application Support/EraseInstall/Packages/` folder. When the package installers are in the correct format (see below) they will be added to the `startosinstall` command with the `--installpackage` option. 

For this to work, the packages have to be 'distribution packages with an'product archives,' i.e. distribution packages with the `identifier` attribute set in the `product` key.

Most package installers created with tools commonly used by Mac Administrators build component packages (also called ‘flat packages’). These contain the payload files that will be installed on the target system and optional installation scripts to modify the behavior.

If you usually build your packages as component packages with `pkgbuild` or a similar tool, you can convert them to product archives with the `productbuild` command:

```
$ productbuild --package path/to/component.pkg --version 1.0 --identifier com.example.package productarchive.pkg
```

If you use a different tool to create your packages, please consult the tool’s manual or support reference whether they create component packages, distribution packages or product archives.
- [munkipkg](https://github.com/munki/munki-pkg): will automatically create product archives when the `distribution_style` key is set to `true
- [Whitebox Packages](http://s.sudre.free.fr/Software/Packages/about.html): identifier (id) and version can be set for a distribution package project when ‘Show Advanced User Options’ is enabled in Packages -> Preferences
- [Jamf Composer](https://www.jamf.com/products/jamf-composer/): cannot create distribution packages or product archives. You can convert the component packages from Composer with the above `productbuild` command.
- `pkgbuild` and most other tools: creates component packages which you can convert using the above `productbuild` command

Source
===================================

The source of the application can be found in the folder [Source](./Source/).

F.A.Q.
===================================
*How secure is the erase that is performed?*
The erase functionality used by the command is higlighted in https://www.apple.com/mac/docs/Apple_T2_Security_Chip_Overview.pdf, on page 6. "When deleting a volume, its volume key is securely deleted by Secure Enclave. This prevents future access with this key even by the Secure Enclave. In addition, all volume keys are wrapped with a media key. The media key doesn’t provide additional confidentiality of data, but instead is designed to enable swift and secure deletion of data because without it, decryption is impossible."

Release Notes
===================================
 
[Release Notes](./RELEASENOTES.md/).

License
===================================
Copyright ©2019 Pro Warehouse.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[![](./readMe_images/pro-logo-enterprise.png)](https://www.prowarehouse.nl)