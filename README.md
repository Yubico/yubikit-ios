# Yubico Mobile iOS SDK (YubiKit)

**YubiKit** is an iOS library provided by Yubico to interact with YubiKeys on iOS devices. 

The library is provided with a [demo application](./YubiKitDemo/README.md) which shows complete examples of how the library can be integrated and demonstrates all the features of this library in an iOS project.

Changes to this library are documented in this [Changelog](Changelog.md).

## **About**

**YubiKit** requires a physical key to test its features. Before running the included [demo application](./YubiKitDemo/README.md) or integrating YubiKit into your own app, you need an NFC-Enabled YubiKey or a YubiKey 5Ci to test functionality.

The host application can build the library as a dependency of the application target when used inside a Xcode workspace. In addition, the  library can be packed using the `build.sh` script, which is provided in the root folder of this project.


## **Transitioning to version 4 of the SDK**

Read the [transitioning document](./docs/transitioning-sdk-4.md) if you already have integrated the previous version of the SDK.

## **Getting Started**

To get started, you can try the [demo](./YubiKitDemo/README.md) as part of this library or start integrating the library into your own application. 

## Try the Demo
The library is provided with a demo application, [**YubiKitDemo**](./YubiKitDemo). The application is implemented in Swift and it shows several examples of how to use YubiKit, including WebAuthn/FIDO2 over the accessory or NFC YubiKeys.

The YubiKit Demo application shows how the library is linked with a project so it can be used for a side-by-side comparison when adding the library to your own project.

## Integrate the library

YubiKit SDK is available as a library and can be added to any new or existing iOS Xcode project through SPM, Cocoapods, or manual setup.

**[SPM Setup]**

The YubiKit SDK for iOS is availble Swift Package Manger (SPM). SPM is a dependency manager built into recent versions of Xcode. Go [here](https://swift.org/package-manager/) to learn more.

1. Open Xcode and click "File" -> "Swift Packages" -> "Add Package Dependency..."

2. Paste the following URL: https://github.com/Yubico/yubikit-ios

3. Click "Next" -> "Next" -> "Finish"

4. If your target project is written in Swift, you need to provide a bridge to the YubiKit library by adding ``#import <YubiKit.h>`` to your bridging header. If a bridging header does not exist within your project, you can add one by following this [documentation](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).

**[Cocoapods Setup]**

The YubiKit SDK for iOS is available through CocoaPods. CocoaPods is a centralized dependency manager for Objective-C and Swift. Go [here](https://guides.cocoapods.org/using/index.html) to learn more.

Add YubiKit to your [Podfile](https://guides.cocoapods.org/using/the-podfile.html).

```ruby
use_frameworks!

pod 'YubiKit', '~> 4.3.0'

```
If you want to have latest changes, replace the last line with:

```ruby

pod 'YubiKit', :git => 'https://github.com/Yubico/yubikit-ios.git'

```

Once YubiKit is added to your `Podfile`, run `pod install` and open the `*.xcworkspace` with Xcode. 

Then import the YubiKit module and you can use its classes and methods.
```
import YubiKit
```

Continue SDK setup by skipping over `Manual Setup` to `Enable Custom Lightning Protocol`.

<details><summary><strong>Manual Setup</strong></summary><p>

Download or Clone YubiKit SDK source
1.  [Download](https://github.com/Yubico/yubikit-ios/releases/) the latest YubiKit SDK (.zip) to your desktop `or` 

    `git clone https://github.com/Yubico/yubikit-ios.git`

**Add YubiKit folder to your Xcode project**

2. Drag the entire `/YubiKit[version]/YubiKit` folder to your Xcode project. Check the option *Copy items if needed*. 
Or add exisiting Yubikit project to your workspace 

**Linked Frameworks and Libraries**

3. `Project Settings` > `General` > `Linked Frameworks and Libraries`.
Click + and add the ``libYubiKit.a``

**Header Search Paths**

4. ``Build Settings`` > Filter by 'Header Search Path'. Set both Debug & Release to ``./YubiKit/**`` (recursive)

**-ObjC flag**

5. Add -ObjC flag
``Build Settings`` > Filter by 'Other Linker Flags'. Add the ``-ObjC`` flag to Debug and Release.

**Bridging-Header**

6. If your target project is written in Swift, you need to provide a bridge to the YubiKit library by adding ``#import <YubiKit/YubiKit.h>`` to your bridging header. If a bridging header does not exist within your project, you can add one by following this [documentation](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).

</details>

---

**Enable Custom Lightning Protocol**

`REQUIRED` if you are supporting the YubiKey 5Ci over the Lightning connector.

> The YubiKey 5Ci is an Apple MFi external accessory and communicates over iAP2. You are telling your app that all communication with the 5Ci as a supported external accessory is via `com.yubico.ylp`.

Open info.plist and add `com.yubico.ylp` as a new item under `Supported external accessory protocols`

**Enable TKSmartCard support**

To support YubiKeys connected via the USB-C port on a device running iOS 16 or higher, you need to add the `com.apple.security.smartcard` entitlement to your application. Note that this connection only support the Smart card based applications on the YubiKey and does not support U2F, FIDO2 or OTP.

**Grant accesss to NFC**

To add support for NFC YubiKeys in your application, follow these steps:

- Add a `NEW` entitlement for reading NFC specific tags, available since iOS 13. This new entitlement is added automatically by Xcode when enabling the **Near Field Communication Tag Reading** capability in the target **Signing & Capabilities**. After enabling the capability the *.entitlements* file needs to contain the `com.apple.developer.nfc.readersession.formats` entitlement:

```xml
...
<dict>
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>TAG</string>  // Application specific tag, including ISO 7816 Tags
    </array>
</dict>
...
```

- The application needs to define the list of `application IDs` or `AIDs` it can connect to, in the *Info.plist* file. The `AID` is a way of uniquely identifying an application on a ISO 7816 tag, which is usually defined by a standard. FIDO2 and U2F use the AID `A0000006472F0001` on most FIDO compliant NFC keys, including the YubiKey. After adding the list of supported AIDs, the *Info.plist* entry should look like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A000000527471117</string> // YubiKey Management Application AID
    <string>A0000006472F0001</string> // FIDO/U2F AID
    <string>A0000005272101</string>   // OATH AID
    <string>A000000308</string>       // PIV AID
    <string>A000000527200101</string> // YubiKey application/OTP AID (for HMAC SHA1 challenge-response)
</array>
</plist>
```

- The *Info.plist* also needs to include a privacy description for NFC usage, using the **NFCReaderUsageDescription** key:

```xml
<key>NFCReaderUsageDescription</key>
<string>The application needs access to NFC reading to communicate with your YubiKey.</string>
```


**Grant accesss to CAMERA**

Optional: if you are planning to use the camera to read QR codes for OTP
Open info.plist and add the following usage:
'Privacy - Camera Usage Description' - "This application needs access to Camera for reading QR codes."

</p>

## Documentation
YubiKit headers are documented and the documentation is available either by reading the header file or by using the QuickHelp from Xcode (Option + Click symbol). Use this documentation for a more detailed explanation of all the methods, properties, and parameters from the API. If you are interested in implementation details for a specific category like U2F, FIDO2, or OATH, check out the [./docs](./docs/) section.

## Using the Library

YubiKit is exposing a simple and easy to use API for executing operations on the YubiKey. The API is divided into `Connections` and `Sessions`. The supported connections are `YKFAccessoryConnection`, `YKFSmartCardConnection` and `YKFNFCConnection`. Each session is started by calling `YubiKitManager.shared.startAccessoryConnection()`, `YubikitManager.shared.startSmartCardConnection()` or `YubiKitManager.shared.startNFCConnection()`. Once a YubiKey connects the SDK delivers the new connection via the `YKFManagerDelegate` protocol. Disconnects are also signaled through the protocol. For an easier and a more Swift-like experience you can implement something similar to this example: [YKFManagerDelegate wrapper](./docs/easy-handling-connections.md).

From a connection you can retrieve any of the sessions currently supported in the SDK. The connections are fetched by calling a method with a callback block. Once the session has been established and the corresponding application on the YubiKey has been selected the callback will return the new session. For e.g a FIDO2 session it would look like this:

##### Swift    

```swift
connection.fido2Session { session, error in
    guard let session = session else { /* handle error and return */ }
    session.verifyPin(pin) { error in
        ...
    }
}
```

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>

[self.connection fido2Session:^(YKFFIDO2Session * _Nullable session, NSError * _Nullable error) {
    if (error) { /* handle error and return */ }
    [session verifyPin:pin completion:^(NSError * _Nullable error) {
        ...
    }];
}];
```

Before initiating the accessory connection, the application should verify that the device running the app supports connecting to the YubiKey over the Lightning port. This can be done by looking at the `supportsMFIAccessoryKey` property on `YubiKitDeviceCapabilities`.

The same goes for the NFC connection and similar to the accessory connection the  `YubiKitDeviceCapabilities` has a property `supportsISO7816NFCTags` that indicates wether the device supports connecting to the YubiKey over NFC.

##### Swift    

```swift
if YubiKitDeviceCapabilities.supportsISO7816NFCTags {
    // Provide additional setup when NFC is available            
    // example
    YubiKitManager.shared.startNFCConnection()
} else {
    // Handle the missing NFC support 
}
```

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
// NFC scanning is available
if (YubiKitDeviceCapabilities.supportsISO7816NFCTags) {
    // Provide additional setup when NFC is available
} else {
    // Handle the missing NFC support
}
```

List of sessions is documented below with it's own specifics and samples:

- [FIDO](./docs/fido2.md) - Provides FIDO2 operations accessible via the *YKFFIDO2Session*.

- [U2F](./docs/u2f.md) - Provides U2F operations accessible via the *YKFU2FSession*.

- [OATH](./docs/oath.md) - Allows applications, such as an authenticator app to store OATH TOTP and HOTP secrets on a YubiKey and generate one-time passwords.

- [OTP](./docs/otp.md) - Provides implementation classes to obtain YubiKey OTP via accessory (5Ci) or NFC.

- [PIV](./docs/piv.md) - Provides PIV operations accessible via the *YKFPIVSession*.

- [Challenge-response](./docs/chr.md) - Provides a method to use HMAC-SHA1 challenge-response.

- [Management](./docs/mgmt.md) - Provides ability to enable or disable available application on YubiKey

- [SmartCardInterface](./docs/smartcard-interface.md) - Provides low level access to the Yubikey with which you can send custom APDUs to the key

## Customize the Library
YubiKit allows customizing some of its behavior by using `YubiKitConfiguration` and `YubiKitExternalLocalization`.
<details><summary><strong>Customizing YubiKit Behavior</strong></summary><p>

For providing localized strings for the user facing messages shown by the library, YubiKit provides a collection of properties in `YubiKitExternalLocalization`.

One example of a localized string is the message shown in the NFC scanning UI while the device waits for a YubiKey to be scanned. This message can be localized by setting the value of `nfcScanAlertMessage`:
	
##### Swift

```swift
let localizedAlertMessage = NSLocalizedString("NFC_SCAN_MESSAGE", comment: "Scan your YubiKey.")
YubiKitExternalLocalization.nfcScanAlertMessage = localizedAlertMessage
```

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
NSString *localizedAlertMessage = NSLocalizedString(@"NFC_SCAN_MESSAGE", @"Scan your YubiKey.");
YubiKitExternalLocalization.nfcScanAlertMessage = localizedNfcScanAlertMessage;
```

For all the available properties and their use look at the code documentation for `YubiKitExternalLocalization`.

---

**Note:**
`YubiKitExternalLocalization` provides default values in English (en-US), which are useful only for debugging and prototyping. For production code always provide localized values.

---


</p>
</details>

## **YubiKit FAQ**

#### Q1. Does YubiKit store any data on the device?

Yubikit doesn't store any data locally on the device. This includes NSUserDefaults, application sandbox folders and Keychain. All the data required to perform an operation is stored in memory for the duration of the operation and then discarded.

#### Q2. Does YubiKit communicate with any services?

Yubikit doesn't communicate with any services, like web services or other type of network communication. YubiKit is a library for sending, receiving and processing the data from a YubiKey.

#### Q3. Can I use YubiKit with other devices which are not from Yubico?

YubiKit is a library which should be used only to interact with a device manufactured by Yubico. While some parts of it may work with other devices, the library was developed and tested to work with YubiKeys. When attaching a MFI accessory, YubiKit will always check if the manufacturer of the device is Yubico before connecting to it.

#### Q4. Is YubiKit compiled with support for Bitcode and Position Independent code?

Yes, YubiKit is compiled to accommodate any modern iOS project. The supplied library is compiled with Position Independent code and Bitcode. The release version of the library is optimized (Fastest, smallest).

#### Q5. Is YubiKit logging or asserting in release mode?

No, YubiKit is not logging in release mode. The logs from YubiKit will show only in debug builds to help the developer to see what YubiKit does. The same stands for assertions. YubiKit will assert in debug mode to warn the developer when invalid parameters are passed to the library or when something unexpected happened with the key. In release, the library will handle invalid states in different ways (e.g. returning nil if the object was not properly initialized, returning errors, etc.).

#### Q6. Are there any versions of iOS where YubiKit does not work?

YubiKit should work on any modern version of iOS (10+) with a few exceptions\*. It's recommended to always ask the users to upgrade to the latest version of iOS to protect them from known, old iOS issues. Supporting the last 2 version of iOS (n and n-1) is usually a good practice to keep the old versions of iOS out. According to [Apple statistics](https://developer.apple.com/support/app-store/), ~90-95% of all iOS devices run the latest 2 versions of iOS because upgrading the OS is free and Apple usually provides a device with upgrades for 5 years.

\* Some versions of iOS had bugs affecting all external accessories. iOS 11.2 was one of them where the applications could not communicate with accessories due to some bugs in the XPC communication. The bug was fixed by Apple in iOS 11.2.6. For these reasons it's recommended to take in consideration rare but possible iOS bugs when designing the application. 

#### Q7. How can I debug the application while using a MFi accessory YubiKey?

Starting from Xcode 9, the IDE provides the ability to debug the application wirelessly. In this way the physical connector is not used for connecting the device to the computer, for debugging the application. This [WWDC session](https://developer.apple.com/videos/play/wwdc2017/404/) explains the wireless debugging functionality in Xcode.

#### Q8. Are the USB-C type iOS devices supported by the YubiKey 5Ci?

The USB-C type iOS devices, such as the iPad Pro 3rd generation, have limited support when using the YubiKey 5Ci or another type of YubiKey with USB-C connector. The OS is not officially supporting external accessories on these devices. However these devices support external USB keyboards, so the OTP functionality of the key will work and the key can be used to generate Yubico OTPs and HOTPs. 

</p>

## **Additional resources**

1. Xcode Help - [Add a capability to a target](http://help.apple.com/xcode/mac/current/#/dev88ff319e7)
2. Xcode Help - [Build settings reference](http://help.apple.com/xcode/mac/current/#/itcaec37c2a6)
3. Technical Q&A QA1490 -
[Building Objective-C static libraries with categories](https://developer.apple.com/library/content/qa/qa1490/_index.html)
4. Apple Developer - [Swift and Objective-C in the Same Project](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html)
5. Yubico - [Developers website](https://developers.yubico.com)
6. Yubico - [Online Demo](https://demo.yubico.com) for OTP and U2F
7. Yubico - [OTP documentation](https://developers.yubico.com/OTP)
8. Yubico - [What is U2F?](https://developers.yubico.com/U2F)
9. Yubico - [YKOATH Protocol Specifications](https://developers.yubico.com/OATH/YKOATH_Protocol.html)
10. FIDO Alliance - [CTAP2 specifications](https://fidoalliance.org/specs/fido-v2.0-ps-20190130/fido-client-to-authenticator-protocol-v2.0-ps-20190130.html)
11. W3.org - [Web Authentication:
An API for accessing Public Key Credentials](https://www.w3.org/TR/webauthn/)
