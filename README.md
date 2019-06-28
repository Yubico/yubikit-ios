# Yubico Mobile iOS SDK - YubiKit 2.0.0 RC1

- **This is a prerelease version of YubiKit. Some of the specifications and APIs may change in the final release. It's recommended to use this documentation and library for prototyping and not for a public release.**
- **Publishing an application which communicates with a YubiKey with lightning connector requires some additional steps before submitting it for an AppStore review. For more details read the [Publishing on AppStore](#appstore_publishing) section.**

---

**YubiKit** is an iOS library provided by Yubico to interact with YubiKeys on iOS devices. 

The library supports NFC-enabled YubiKeys and provides the APIs to request an OTP (Yubico OTP or HOTP) from the NFC YubiKeys using a NFC-enabled iOS device. The library provides also a built-in QR Code reader which can be used as an alternative enrolment mechanism for iOS devices which don't support NFC reading. 

Starting from version 2.0.0, YubiKit adds support for YubiKeys with lightning connector, such as the YubiKey 5Ci, a security key design by Yubico for iOS devices.

The library is provided with a demo application which shows a complete example of how to integrate and use all the features of the library in an iOS project.

The differences between the library versions are documented in this [Changelog](Changelog.md).

## Table of contents

1. [Prerequisites](#prerequisites)
2. [Integration steps](#integration_steps)
	- 2.1 [Prepare the project](#integration_steps_1)
	- 2.2 [Add the library](#integration_steps_2)
	- 2.3 [Use the library](#integration_steps_3)
		- 2.3.1 [NFC and the QR Code fallback](#integration_steps_3_1)
		- 2.3.2 [U2F operations with the YubiKey 5Ci](#integration_steps_3_2)
		- 2.3.3 [OATH operations with the YubiKey 5Ci](#integration_steps_3_3)
		- 2.3.4 [Reading OTPs from the YubiKey 5Ci](#integration_steps_3_4)
		- 2.3.5 [Using the Raw Command Service and the PC/SC like interface](#integration_steps_3_5)
		- 2.3.6 [FIDO2 operations with the YubiKey 5Ci](#integration_steps_3_6)
3. [Customising YubiKit](#customising_yubikit)
4. [Using the demo application](#using_demo)
5. [Publishing on AppStore](#appstore_publishing)
6. [FAQ](#faq)
7. [Additional resources](#additional_resources)

<a name="prerequisites"></a>
## 1. Prerequisites

**YubiKit** requires access to NFC to interact with a NFC-enabled YubiKey. NFC reading is available as a public API since iOS 11 on iPhone 7 and newer devices. The library provides capabilities check which can be used to detect if the device supports NFC reading or not.

YubiKit is provided as a static library<sup>[1]</sup> to maximise the compatibility with various projects written in Objective-C or Swift, using older or newer versions of Xcode. The library comes in two flavours, **debug_universal** and **release**. As the names suggest, the first one is intended for development use only, compatible with both the iOS simulator and iOS devices, while the release version must be used for release distributions, including AppStore/TestFlight, AdHoc and Enterprise.

**[1]** Starting from YubiKit 2.0.0 RC1, the open source version of the library is available on GitHub. The host application can build the static library as a dependency of the application target when used inside a Xcode workspace. Additionally to this setup the static library can be packed using the `build.sh` script which is provided in the root folder of the library.

<a name="integration_steps"></a>
## 2. Integration steps

<a name="integration_steps_1"></a>
### 2.1 Prepare the project 

Depending on the requirements of the application, the project may use all or just some features of YubiKit. If the application is using the NFC reader, follow the steps to configure the project from **Configure the project to use the built-in NFC and QR Code readers**. If the application requires to communicate with a YubiKey with lightning connector, jump to **Enable the application to communicate with a YubiKey with lightning connector**.

---

**Note:**
Some old versions of the AppStore API analyser were scanning the project for used APIs, when submitting, and still require some capabilities to be set even when using only parts of the YubiKit library. This should no longer happen and the API analyser will check only for the used code. The developer tools will strip the unused symbols when optimising the binary for release so those parts of the library are not actually part of the released application binary. The linker will link only the parts of the code which are used from the library into the final application binary (e.g. If the NFC API from YubiKit is not used the application binary will not include any NFC related code from YubiKit).

---

#### Configure the project to use the built-in NFC and QR Code readers

Before adding the library, the project needs to have access permissions for NFC and Camera. Camera access permission is required when using the built-in QR Code reader.

The NFC support requires to add a new entitlement to the project, called **Near Field Communication Tag Reading**. To turn it on, Xcode provides an automatic way of doing it by selecting the desired target (usually the app target) and turning on the associated switch in the **Capabilities** tab. If the project has already an entitlements file for other features (like iCloud, Notifications etc.), the new entitlement will be added to the existing file. If the project doesn't have an entitlements file, Xcode will create one and add it to the project. Additionally the new entitlement needs to be enabled in the Developer portal. If possible, Xcode will do this automatically. 

---

**Note:**
If the entitlement is not enabled the iOS SDK may hang up the main thread on startup and eventually will fail after some time, when the application is trying to access the NFC APIs. 

---

After enabling the entitlement, iOS requires from the application to provide a NFC usage description defined in the *info.plist* file. To add it follow the standard way of adding a new key to the info.plist and search for **Privacy - NFC Scan Usage Description**. This property is a string describing the intent for using NFC.

If the application is using the built-in QR Code reader, since iOS 10 the application needs to provide a reason for accessing the camera. Add it in the same way as setting the description for NFC access, using **Privacy - Camera Usage Description** key instead. This value will be shown during camera permission request dialog, displayed by the OS.

---

**Note:**
The iOS SDK doesn't display a permission dialog before giving access to NFC, even it requires a NFC usage description in the *info.plist*.

---

#### Enable the application to communicate with a YubiKey with lightning connector

To interact with a YubiKey with lightning connector, the application needs to inform the OS that it's able to talk to an external accessory which communicates over a list of specified protocols. The YubiKey 5Ci communicates over a protocol called **com.yubico.ylp**. To enable this capability follow these steps:

* Open your *info.plist* file and a new entry for **Supported external accessory protocols**. The corresponding plist key for this property is **UISupportedExternalAccessoryProtocols**. The value of this key is an array of protocols the application can use to talk to an external accessory. 
* Add to the list a new item with the value **com.yubico.ylp**. YLP stands for *Yubico Lightning Protocol*.

Now the OS will allow the application to establish a communication channel with the YubiKey when the key is plugged in the lightning port. The Demo application of the library also includes this capability.

---

**Notes:**

1. Starting from iOS 11.4.1 Apple introduced a new security measure called *USB Restricted Mode*. This feature does not affect the YubiKey 5Ci. To perform operations with the key, the user needs to unlock the device and actively use the application which is interacting with the key. For more details about this new feature check this [documentation](https://support.apple.com/en-us/HT208857).

2. On iOS an application can be configured to talk to an external accessory while in background. This is defined by using the *background modes* list accessible in modern Xcode versions from the target Capabilities tab. It is **not recommended** to enable the background mode when using the YubiKey because the user needs to be active in the authentication process.

---

<a name="integration_steps_2"></a>
### 2.2 Add the library

The library is archived into a Zip file named YubiKit\[version] where version is the version number of the packed library. Follow the next steps to add the library to the project:

* Unzip the library archive. After unzipping the result is a folder which contains the documentation, the license and two folders, **YubiKit**, the library flavours and header files, and **YubiKitDemo**, the demo application for the library.
* Copy the **YubiKit** folder into the host application project folder. 
* In the project select the app target and in the **General** tab look for **Linked Frameworks and Libraries**. Click + and select **Add Other**. Locate the **libYubiKit.a** in **YubiKit/debug_universal** folder and add it. 
* Select **Build Settings** tab for the target. Filter the settings by searching after **Library search paths** and expand the configuration to see both **debug** and **release**. Update the **release** path to point at the **YubiKit/release** folder of the library and the **debug** path to point at the **YubiKit/debug_universal** folder.
* Filter the settings by **Header search paths**, add the path to the **YubiKit** folder, and make it recursive.
* Filter the settings by **Other Linker flags**  and add **-ObjC** to allow the linker to properly load categories from static libraries (some versions of Xcode may create projects with this flag by default). If this flag is not enabled a runtime exception will be thrown as described in this [technical note](https://developer.apple.com/library/archive/qa/qa1490/_index.html) from Apple.

Now the application is able to link with libYubiKit.a and to properly select the right library flavour when building for debug or release.

When building the source code of the library, the static library can be linked as a build dependency of the application target. Xcode will take care of building the right flavour of the library when building the application target for debug or release.

<a name="integration_steps_3"></a>
### 2.3 Use the library

If the target project is written in Swift, the library needs to be bridged first. Add `#import <YubiKit/YubiKit.h>` to the bridging header. If the bridging header is not available add one by following this [documentation](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).

YubiKit provides the majority of its functionality through a single instance called `YubiKitManager` which is retrieved by accessing the `YubiKitManager.shared` property. YubiKitManager is a singleton and the library prevents an instance creation by the host application. YubiKitManager is structured to provide a list of _sessions_, each one of them being dedicated to only one type of communication. For details look at the available properties on `YubiKitManager`.


<a name="integration_steps_3_1"></a>
#### 2.3.1 OTP - NFC and the QR Code fallback

To request a NFC scan for an OTP token call `requestOTPToken:` on the `nfcReaderSession` instance from `YubiKitManager`:

##### Objective-C		

```objective-c
#import <YubiKit/YubiKit.h>
...
[YubiKitManager.shared.nfcReaderSession requestOTPToken:^(id<YKFOTPTokenProtocol> token, NSError *error) {
    NSString *tokenValue = token.value;
    // Start using the token value
    ...
}];
```	
##### Swift

```swift
YubiKitManager.shared.nfcReaderSession.requestOTPToken { [weak self] (token, error) in
    if let value = token?.value {
        // Start using the token value
        ...                
    }	
}
```

The `YKFOTPToken` contains the details of the scanned OTP token. The detailed documentation of all the properties is available in the header files provided with the library.

---

To request a QR Code scan call `scanQrCodeWithPresenter:completion:` on the `qrReaderSession` instance from `YubiKitManager`:

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
// Here self is a view controller.
[YubiKitManager.shared.qrReaderSession scanQrCodeWithPresenter:self completion:^(NSString *payload, NSError *error) {
    // Start using the payload
    // ...
}];
```	
##### Swift    

```swift
// Here self is a view controller.
YubiKitManager.shared.qrReaderSession.scanQrCode(withPresenter: self) { [weak self] (payload, error) in    
    // Start using the payload
    // ...	
}
```

In the current version of YubiKit the library doesn't make any assumption about the format of the scanned QR code payload but this may change in future versions.

---

Before calling the APIs for NFC or QR Code scanning it is recommended to check for the capabilities of the OS/Device. If the device or the OS does not support a capability **the library will fire an assertion** in debug builds when calling a method without having the required capability. YubiKit provides a handy utility class to check for these capabilities: `YubiKitDeviceCapabilities`:

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
// 1. NFC scanning is available
if (YubiKitDeviceCapabilities.supportsNFCScanning) {
    // Provide additional setup when NFC is available
} else {
    // Handle the missing NFC support
}
	
// 2. QR Code scanning is available
if (YubiKitDeviceCapabilities.supportsQRCodeScanning) {
    // Provide additional setup when QR Code scanning is available 
} else {
    // Handle the missing QR code support
}
```
		
##### Swift	

```swift
if YubiKitDeviceCapabilities.supportsNFCScanning {
    // Provide additional setup when NFC is available            
} else {
    // Handle the missing NFC support 
}

if YubiKitDeviceCapabilities.supportsQRCodeScanning {
    // Provide additional setup when QR Code scanning is available             
} else {
    // Handle the missing QR code support
}
```

---

To allow the library to be linked with older projects, some of the APIs in YubiKit use availability annotations. One example is the presence of the NFC APIs available only from iOS 11. If the host application needs to run on older devices, by compiling the project for older versions of iOS, and still provide new features for users with newer devices, you can use `@available/#available` before calling the APIs which require iOS 11 and above.

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
if (@available(iOS 11.0, *)) {
    // Call the NFC APIs                
}
```

##### Swift

```swift
if #available(iOS 11.0, *) {
    // Call the NFC APIs	
}
```

---

**Note:**
To use *@available* in Obj-C the project needs to be compiled with Xcode 9 or newer.

---

#### Putting everything together

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
- (void)requestOTPToken {
    if (!YubiKitDeviceCapabilities.supportsNFCScanning) {
        // The device does not support NFC reading
        return;
    }    
    if (@available(iOS 11.0, *)) {
        [YubiKitManager.shared.nfcReaderSession requestOTPToken:^(id<YKFOTPTokenProtocol> token, NSError *error) {
            if (error != nil) {
                // Process the error
                return;
            }
            // Process the token
        }];
    }
}

- (void)requestQRCodeScan {
    if (!YubiKitDeviceCapabilities.supportsQRCodeScanning) {
        // The device does not support QR code scanning
        return;
    }    
    [YubiKitManager.shared.qrReaderSession scanQrCodeWithPresenter:self completion:^(NSString *payload, NSError *error) {
        if (error != nil) {
            // Process the error
            return;
        }
        // Process the payload
    }];
}
```

##### Swift

```swift
func requestOTPToken() {
    guard YubiKitDeviceCapabilities.supportsNFCScanning else {
        // The device does not support NFC reading
        return
    }
    
    if #available(iOS 11.0, *) {
        YubiKitManager.shared.nfcReaderSession.requestOTPToken { [weak self] (token, error) in
            guard error == nil else {
                // Process the error
                return
            }
            // Process the token
        }
    }
}
    
func requestQRCodeScan() {
    guard YubiKitDeviceCapabilities.supportsQRCodeScanning else {
        // The device does not support QR code scanning
        return
    }
    YubiKitManager.shared.qrReaderSession.scanQrCode(withPresenter: self) { [weak self] (payload, error) in
        guard error == nil else {
            // Process the error
            return
        }
        // Process the payload
    }
}
```

<a name="integration_steps_3_2"></a>
#### 2.3.2 U2F operations with the YubiKey 5Ci

The *Universal Second Factor* or U2F protocol is a simple yet powerful way of providing strong authentication for users. The goal of this documentation is not to provide a full explanation of U2F but to explain how to use U2F with YubiKit and the YubiKey 5Ci. For a more detailed explanation of U2F you are encouraged to access the resources from Yubico [developer website](https://developers.yubico.com). For a general overview of U2F consult this [introduction article](https://developers.yubico.com/U2F/) from Yubico developers website.

U2F provides two major operations: **registration** and **authentication** (which is often referred as *signing*). To provide strong security these operations need to be performed in an isolated and secure environment, such as the YubiKey. The YubiKey has a secure element inside, a special hardware module that guarantees that no secrets can be extracted from the device. YubiKit provides the ability to communicate with the YubiKey 5Ci which can perform these operations. 

The U2F operations can be logically separated in 3 steps:

1. The application is requesting from the authentication server some information which is required by the YubiKey to perform the operation. 
2. The application is sending that information to the YubiKey and waits for a result.
3. The application sends the result to the authentication server to be validated.

Steps 1 and 3 are custom to each application. This usually involves some HTTPS calls to the server infrastructure used by the application to get and send data back. The second step is where the application is using YubiKit and the YubiKey.

***Hint: Use the demo application and search for relevant code while reading this guide and consult also the code level documentation for a more detailed explanation.***

YubiKit is exposing a simple and easy to use API for U2F operations which hides the complexity of managing the logic of interacting with an external accessory on iOS and communicating U2F specific binary data to the key. The U2F operations are accessible via the `YKFKeyU2FService`, a shared single instance which becomes available in `YubiKitManager.keySession` when the session with the key is started. 

To enable the `YKFKeySession` to receive events and connect to the YubiKey 5Ci, it needs to be explicitly started. This allows the host application to have a granular control on when the application should listen and connect to the key. When the application no longer requires the presence of the key (e.g. the user successfully authenticated and moved to the main UI of the app), the session can be stopped by calling `stopSession`.

---

**Notes:**

1. In the YubiKit Demo application the session is started at launch and remains active throughout the lifetime of the application to demo the U2F functionality. Usually the session should be started when an authentication UI is displayed and stopped when it goes away. In this way YubiKit does not retain unnecessary resources.

2. Before starting the key session, the application should verify if the iOS version is supported by the library by looking at the `supportsLightningKey` property on `YubiKitDeviceCapabilities`

---

An important property of the `YKFKeySession` is the `sessionState` which can be used to check the state of the session. This property can be observed using KVO. Observe this property to see when the key is connected or disconnected and take appropriate actions to update the UI and to send requests to the key. Because the KVO code can be verbose, a complete example on how to observe this property is provided in the Demo application and not here. When the host application prefers a delegate pattern to observe this property, the YubiKit Demo application provides an example on how to isolate the KVO observation into a separate class and use a delegate to update about changes. The example can be found in the `Examples/Observers` project group.

The session was designed to provide a list of *services*. A service usually maps a major capability of the key, in this case U2F. Over the same session the application can talk to different functionalities provided by the key. The `YKFKeyU2FService` will communicate with the U2F functionality from the key. The U2F service lifecycle is fully controlled by the key session and it must not be created by the host application. The lifecycle of the U2F service is dependent on the session state. When the session is opened and it can communicate with the key, the U2F service become available. If the session is closed the U2F service is `nil`.

After the key session was started and a key was connected the session state becomes *open* so the application can start sending requests to the key.

To send an U2F registration request to the key call `executeRegisterRequest:completion:` on the U2F service. This method takes as a parameter the request object of type `YKFKeyU2FRegisterRequest` which packs a list of all required parameters by the key to perform the registration. `YKFKeyU2FRegisterRequest` contains all the required code level documentation and external links to understand its properties. The `completion` parameter is a block/closure which will be called asynchronously when the operation with the key has ended. The operation with the key is executed on a background execution queue and the `completion` block will be called from that queue. Consider this when planning to update things which require to be executed on the main thread, like the UI updates.

##### Objective-C

```objective-c
// The challenge and appId are received from the authentication server.
YKFKeyU2FRegisterRequest *registerRequest = [[YKFKeyU2FRegisterRequest alloc] initWithChallenge:challenge appId:appId];
    
[YubiKitManager.shared.u2fService executeRegisterRequest:registerRequest completion:^(YKFKeyU2FRegisterResponse *response, NSError *error) {
    if (error) {				
        // Handle the error
        return;
    }
    // The response should not be nil at this point. Send back the response to the authentication server.
}];
```

##### Swift
	
```swift
// The challenge and appId are received from the authentication server.
let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId)
	
YubiKitManager.shared.keySession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
    guard error == nil else {
        // Handle the error
        return
    }
    // The response should not be nil at this point. Send back the response to the authentication server.
}
```

To send an U2F sign request to the key call `executeSignRequest:completion:` on the U2F service. This method takes as a parameter the request object of type `YKFKeyU2FSignRequest` which packs a list of all required parameters by the key to perform the signing. `YKFKeyU2FSignRequest` contains all the required code level documentation and external links to understand its properties. The `completion` parameter is a block/closure which will be called asynchronously when the operation with the key has ended. The operation with the key is executed on a background execution queue and the `completion` block will be called from that queue. Consider this when planning to update things which require to be executed on the main thread, like the UI updates.

##### Objective-C

```objective-c
// The challenge, keyHandle and appId are received from the authentication server.
YKFKeyU2FSignRequest *signRequest = [[YKFKeyU2FSignRequest alloc] initWithChallenge:challenge keyHandle:keyHandle appId:appId];
    
[YubiKitManager.shared.u2fService executeSignRequest:signRequest completion:^(YKFKeyU2FSignResponse *response, NSError *error) {        
    if (error) {
        // Handle the error
        return;
    } 
    // The response should not be nil at this point. Send back the response to the authentication server.        
}];
```

##### Swift

```swift
// The challenge, keyHandle and appId are received from the authentication server.
let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId)
	
YubiKitManager.shared.keySession.u2fService!.execute(signRequest) { [weak self] (response, error) in
    guard error == nil else {
        // Handle the error here.
        return
    }
    // Response should not be nil at this point. Send back the response to the authentication server.
}
```
	
<a name="integration_steps_3_3"></a>	
#### 2.3.3 OATH operations with the YubiKey 5Ci

The [YKOATH protocol](https://developers.yubico.com/OATH/YKOATH_Protocol.html) is used to manage and use OATH credentials with a YubiKey. The YKOATH protocol is part of the CCID interface of the key. The CCID interface is enabled by default on the YubiKey 5Ci. 

YubiKit provides OATH support through a single shared instance, `oathService` (of type `YKFKeyOATHService`), a property of the `YKFKeySession`. The OATH service is very similar in behaviour with the U2F service from the Key Session. It will receive requests and dispatch them asynchronously to be executed by the key. The OATH service is available only when the key is connected to the device and there is an opened session with the key. If the key session is closed or the key is disconnected the `oathService` property is `nil`. 

The `sessionState` property on the Key Session can be observed to check the state of the session and take appropriate actions to update the UI or to send requests to the key. 

The OATH Service provides a method for every command from the YOATH protocol to add, remove, list and calculate credentials. For the complete list of methods look at the `YKFKeyOATHService` code level documentation. 

YubiKit provides also a class for defining an OATH Credential, `YKFOATHCredential`, which has a convenience initialiser which can receive a credential URL conforming to the [Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format) and parse the credential parameters from it.

Here are a few snippets on how to use the OATH functionality of the YubiKey through YubiKit:

##### Objective-C

```objective-c
// This is an URL conforming to Key URI Format specs.
NSString *oathUrlString = @"otpauth://totp/Yubico:example@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
NSURL *url = [NSURL URLWithString:oathUrlString];
NSAssert(url != nil, @"Invalid OATH URL");
    
// Create the credential from the URL using the convenience initializer.
YKFOATHCredential *credential = [[YKFOATHCredential alloc] initWithURL:url];
NSAssert(credential != nil, @"Could not create OATH credential.");
    
id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.keySession.oathService;
if (!oathService) {
    return;
}
    
/*
 * Example 1: Adding a credential to the key
 */
 
YKFKeyOATHPutRequest *putRequest = [[YKFKeyOATHPutRequest alloc] initWithCredential:credential];
if (!putRequest) {
    return;
}
    
[oathService executePutRequest:putRequest completion:^(NSError * _Nullable error) {
    if (error) {
        NSLog(@"The put request ended in error %@", error.localizedDescription);
        return;
    }
    // The request was successful. The credential was added to the key.
}];
    
/*
 * Example 2: Removing a credential from the key
 */
 
YKFKeyOATHDeleteRequest *deleteRequest = [[YKFKeyOATHDeleteRequest alloc] initWithCredential:credential];
if (!deleteRequest) {
    return;
}

[oathService executeDeleteRequest:deleteRequest completion:^(NSError * _Nullable error) {
    if (error) {
        NSLog(@"The delete request ended in error %@", error.localizedDescription);
        return;
    }
    // The request was successful. The credential was removed from the key.
}];
    
/*
 * Example 3: Calculating a credential with the key
 */
    
YKFKeyOATHCalculateRequest *calculateRequest = [[YKFKeyOATHCalculateRequest alloc] initWithCredential:credential];
if (!calculateRequest) {
    return;
}
    
[oathService executeCalculateRequest:calculateRequest completion:^(YKFKeyOATHCalculateResponse * _Nullable response, NSError * _Nullable error) {
    if (error) {
        NSLog(@"The calculate request ended in error %@", error.localizedDescription);
        return;
    }
    NSAssert(response, @"If the error is nil the response cannot be empty.");
    
    NSString *otp = response.otp;
    NSLog(@"OTP value for the credential %@ is %@", credential.label, otp);
}];
    
/*
 * Example 4: Listing credentials from the key
 */
 
[oathService executeListRequestWithCompletion:^(YKFKeyOATHListResponse * _Nullable response, NSError * _Nullable error) {
    if (error) {
        NSLog(@"The list request ended in error %@", error.localizedDescription);
        return;
    }
    NSAssert(response, @"If the error is nil the response cannot be empty.");

    NSArray *credentials = response.credentials;
    NSLog(@"The key has %ld stored credentials.", (unsigned long)credentials.count);
}];
```

##### Swift

```swift
// This is an URL conforming to Key URI Format specs.
let oathUrlString = "otpauth://totp/Yubico:example@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30"
guard let url = URL(string: oathUrlString) else {
    fatalError()
}
    
// Create the credential from the URL using the convenience initializer.
guard let credential = YKFOATHCredential(url: url) else {
    fatalError()
}
    
guard let oathService = YubiKitManager.shared.keySession.oathService else {
    return
}
    
/*
 * Example 1: Adding a credential to the key
 */ 
         
guard let putRequest = YKFKeyOATHPutRequest(credential: credential) else {
    return
}
oathService.execute(putRequest) { (error) in
    guard error == nil else {
        print("The put request ended in error \(error!.localizedDescription)")
        return
    }
    // The request was successful. The credential was added to the key.
}
    
/*
 * Example 2: Removing a credential from the key
 */        
 
guard let deleteRequest = YKFKeyOATHDeleteRequest(credential: credential) else {
    return
}
oathService.execute(deleteRequest) { (error) in
    guard error == nil else {
        print("The delete request ended in error \(error!.localizedDescription)")
        return
    }
    // The request was successful. The credential was removed from the key.
}
    
/* 
 * Example 3: Calculating a credential with the key
 */        
 
guard let calculateRequest = YKFKeyOATHCalculateRequest(credential: credential) else {
    return
}
oathService.execute(calculateRequest) { (response, error) in
    guard error == nil else {
        print("The calculate request ended in error \(error!.localizedDescription)")
        return
    }
    // If the error is nil the response cannot be empty.
    guard response != nil else {
        fatalError()
    }
    
    let otp = response!.otp
    print("The OTP value for the credential \(credential.label) is \(otp)")
}

/*
 * Example 4: Listing credentials from the key
 */ 
 
oathService.executeListRequest { (response, error) in
    guard error == nil else {
        print("The list request ended in error \(error!.localizedDescription)")
        return
    }
    // If the error is nil the response cannot be empty.
    guard response != nil else {
        fatalError()
    }
    
    let credentials = response!.credentials
    print("The key has \(credentials.count) stored credentials.")
}
```
	
In addition to these requests, the OATH Service provides an interface for setting/validating a password on the OATH application, calculate all credentials and resetting the OATH application to its default state.

---

**Tips:**
Authenticators often use QR codes to pass the URL for setting up the credentials. The built-in QR Code reader from YubiKit can be used to read the credential URL.

---
	
<a name="integration_steps_3_4"></a>	
#### 2.3.4 Reading OTPs from the YubiKey 5Ci

Unlike the other functionalities from the YubiKey 5Ci, the OTP generation does not require an explicit call to YubiKit to fetch the OTP. The OTP generation works in a similar way with the generation of OTPs with an USB key. The YubiKey 5Ci acts as an external keyboard when sending the OTP to the OS. 

The OTP generation mechanism follows these steps when outputting the OTP into a preexisting text field which is the first responder, like a focused text field inside a web page:

1. The user plugs the key into the lightning port.
2. The user is touching the key.
3. The key will start emulating an external keyboard which will cause the virtual keyboard (if present) to be temporary dismissed.
4. The OTP is sent to the OS.
5. After the OTP transmission the key stops emulating the keyboard so the virtual keyboard will be again enabled.

Most of the time the OTP value is not important for the user so displaying it does not bring a significant value. In such a case the iOS frameworks provide several ways of intercepting the keyboard input without displaying a text field or the virtual keyboard. This allows to improve the UX by reading the OTP from the key with less steps while showing an explanatory UI to the user. The techniques to achieve this are application specific and mostly depend on the preferences of the developers.

One way of intercepting the keyboard input is to use `UIKeyCommand`. Key commands are usually used to intercept key combinations from the external keyboard and they can be attached to any `UIResponder`. The most common UIResponders are `UIView` and `UIViewController`. These fundamental classes of UIKit have the ability to `becomeFirstResponder` and they provide a property called `keyCommands` which can return a list of commands which will be triggered when the user is pressing a certain key combination on the external keyboard. An `UIKeyCommand` doesn't have to be a key combination. A certain character can be detected if the key command is created without modifiers. An example of such responder, `OTPUIResponder`, is implemented in the YubiKit Demo application. In the OTP demo the application will intercept the keyboard input using the `OTPUIResponder` to read the OTP from the YubiKey.

Sometimes the UX may involve some guiding steps for the user to plugin or to touch the key. In such a scenario YubiKit can be used to determine if the key is plugged in, in the same way as it's done in the FIDO2 demo, by observing the `sessionState` on `YKFKeySession`.

<a name="integration_steps_3_5"></a>
#### 2.3.5 Using the Raw Command Service and the PC/SC like interface 

In some scenarios the application may require to interact with the YubiKey in a very specific way which is not covered by the existing key services. Such scenarios may include:

1. The application needs to interact with multiple key applications inside a very complex flow.
2. YubiKit may not provide a service to a not very commonly used key application.
3. The application has already integrations with other libraries/accessories and there is an existing architecture which implements a binary communication with them.
4. Some specific project or design requirements.

---

**Note:**
It is recommended to use high level APIs when possible because they already provide a good integration with the key (e.g. If the application wants to perform U2F requests it's better to use the provided U2F Service instead of reimplementing the logic inside the application over the raw interface).

---

For such scenarios YubiKit allows to send raw commands to the key over two channels: using the `YKFKeyRawCommandService` or over a `PC/SC like` interface. 

The `YKFKeyRawCommandService` provides a simple API for sending synchronous and asynchronous requests to the key. In the following example the application executes a request for selecting the PIV application from the card:

##### Objective-C

```objective-c
 #import <YubiKit/YubiKit.h>
  
 ...

id<YKFKeyRawCommandServiceProtocol> rawCommandService =  YubiKitManager.shared.keySession.rawCommandService;
if (!rawCommandService) {
    // The key is not connected or the key session is not started if the rawCommandService is nil.
    return;
}
    
UInt8 command[] = {0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08};
NSData *commandData = [NSData dataWithBytes:command length:10];
    
// Method #1: 
// Build the APDU with data
    
YKFAPDU *apdu = [[YKFAPDU alloc] initWithData:commandData];
    
// Method #2: 
// Build the APDU by specifying the components
    
UInt8 apduDataBytes[] = {0xA0, 0x00, 0x00, 0x03, 0x08};
NSData *apduData = [NSData dataWithBytes:apduDataBytes length:5];
apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0xA4 p1:0x04 p2:0x00 data:apduData type:YKFAPDUTypeShort];
    
if (!apdu) {
    // The supplied data to build the APDU was invalid.
    return;
}
    
// Example #1:
// Asynchronous command execution. The [executeCommand:] can be called from any thread.
    
[rawCommandService executeCommand:apdu completion:^(NSData *response, NSError * error) {
    if (error) {
        // Handle the error
        return;
    }
    // Use the response from the key
    NSAssert(response, @"The response cannot be nil at this point.");
}];
    
// Example #2:
// Synchronous command execution. The [executeCommand:] must be called from a background thread.
    
[rawCommandService executeSyncCommand:apdu completion:^(NSData *response, NSError * error) {
    if (error) {
        // Handle the error
        return;
    }
    // Use the response from the key
    NSAssert(response, @"The response cannot be nil at this point.");
}];
```    
	
##### Swift

```swift
guard let rawCommandService = YubiKitManager.shared.keySession.rawCommandService else {
    // The key is not connected or the key session is not started if the rawCommandService is nil
    return
}
    
// Method #1: 
// Build the APDU with data
    
let command: [UInt8] = [0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08]
let commandData = Data(bytes: command)
    
guard let firstApdu = YKFAPDU(data: commandData) else {
    // The supplied data to build the APDU was invalid
    return
}
    
// Method #2: 
// Build the APDU by specifying the components
    
let apduDataBytes: [UInt8] = [0xA0, 0x00, 0x00, 0x03, 0x08]
let apduData = Data(bytes: apduDataBytes)
guard let secondApdu = YKFAPDU(cla: 0x00, ins: 0xA4, p1: 0x04, p2: 0x00, data: apduData, type: .short) else {
    // The supplied data to build the APDU was invalid.
    return
}
    
// Example #1:
// Asynchronous command execution. The executeCommand() can be called from any thread.
    
rawCommandService.executeCommand(firstApdu) { (response, error) in
    guard error == nil else {
        // Handle the error
        return
    }
    assert(response != nil, "The response cannot be nil at this point.")
    // Use the response from the key
}
    
// Example #2:
// Synchronous command execution. The executeCommand() must be called from a background thread.
    
rawCommandService.executeSyncCommand(secondApdu) { (response, error) in
    guard error == nil else {
        // Handle the error
        return
    }
    assert(response != nil, "The response cannot be nil at this point.")
    // Use the response from the key
}    
```    
    
The YubiKit Demo application has a more detailed demo on how to use the Raw Command service in `RawCommandServiceDemoViewController`.
    
YubiKit provides also a `PC/SC like` interface for sending raw commands to the key. This interface is exposed in `YKFPCSC.h`. For a complete list of methods consult the header file and the code level documentation.

---

**Note:**
In iOS there is no native concept of PC/SC. This interface is just an adaptation of the PC/SC interface, specific to YubiKit. The reason to have this interface is to provide a familiar API for the developers who are used to the PC/SC interface. The PC/SC is a low level C API which can be sometimes harder to use than the Raw Command service. If possible, it's recommended to use the Raw Command Service because it's designed to be integrated easier with an iOS application.  

---

Below there is an example on how to use the PC/SC interface to send a raw APDU command to the key and read the response. For a more detailed example look at the YubiKit Demo application which provides a demo on how to read a certificate from the PIV key application and use it to verify a signature, in `PCSCDemoViewController`.

##### Objective-C
    
```objective-c    
 #import <YubiKit/YubiKit.h>
 
 ...
    
/*
 1. Establish the context.
 */
    
SInt32 context = 0;
SInt64 result = 0;
    
result = YKFSCardEstablishContext(YKF_SCARD_SCOPE_USER, nil, nil, &context);
    
if (result != YKF_SCARD_S_SUCCESS) {
    NSLog(@"Could not establish a context.");
    return;
}
    
/*
 2. Get the readers and check for key presence. There is only one in this case.
 */
    
// Ask for the readers length.
UInt32 readersLength = 0;
    
result = YKFSCardListReaders(context, nil, nil, &readersLength);
if (result != YKF_SCARD_S_SUCCESS || readersLength == 0) {
    if (result == YKF_SCARD_E_NO_READERS_AVAILABLE) {
        NSLog(@"Could not ask for readers length. The key is not connected.");
    } else {
        NSLog(@"Could not ask for readers length (%d).", (int)result);
    }
    
    YKFSCardReleaseContext(context);
    return;
}
    
// Allocate the right buffer size and get the readers
char readers[readersLength];
result = YKFSCardListReaders(context, nil, readers, &readersLength);
    
if (result != YKF_SCARD_S_SUCCESS) {
    if (result == YKF_SCARD_E_NO_READERS_AVAILABLE) {
        NSLog(@"Could not list the readers. The key is not connected.");
    } else {
        NSLog(@"Could not list readers (%d).", (int)result);
    }
    
    YKFSCardReleaseContext(context);
    return;
}
NSLog(@"Reader %@ connected.", [NSString stringWithUTF8String:readers]);
    
// Get the status
YKF_SCARD_READERSTATE readerState;
readerState.currentState = YKF_SCARD_STATE_UNAWARE;
    
result = YKFSCardGetStatusChange(context, 0, &readerState, 1);
if (result != YKF_SCARD_S_SUCCESS) {
    NSLog(@"Could not get the status change (%d).", (int)result);
    
    YKFSCardReleaseContext(context);
    return;
}
    
if ((readerState.eventState & YKF_SCARD_STATE_PRESENT) != 0) {
    NSLog(@"The key is not connected.");
}
    
/*
 3. Connect to the key.
 */
    
SInt32 card = 0;
UInt32 activeProtocol = YKF_SCARD_PROTOCOL_T1;
    
result = YKFSCardConnect(context, readers, YKF_SCARD_SHARE_EXCLUSIVE, YKF_SCARD_PROTOCOL_T1, &card, &activeProtocol);
    
if (result != YKF_SCARD_S_SUCCESS) {
    NSLog(@"Could not connect to the key (%d).", (int)result);
    
    YKFSCardReleaseContext(context);
    return;
}
    
/*
 4. Create a reusable buffer.
 */
UInt32 transmitRecvBufferMaxSize = 258;
UInt8 transmitRecvBuffer[transmitRecvBufferMaxSize];
UInt32 transmitRecvBufferLength = transmitRecvBufferMaxSize;
    
/*
 5. Send a command.
 */
    
UInt8 command[] = {0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08};
    
result = YKFSCardTransmit(card, nil, command, 10, nil, transmitRecvBuffer, &transmitRecvBufferLength);
    
if (result != YKF_SCARD_S_SUCCESS) {
    NSLog(@"Could not execute the command (%d).", (int)result);
    
    YKFSCardReleaseContext(context);
    return;
} else {
    // Handle the response
}
    
/*
 6. Release the context.
 */
YKFSCardReleaseContext(context);    
```
    
##### Swift        

```swift    
/*
 1. Establish the context.
 */
    
var context: Int32 = 0
var result: Int64 = 0
    
result = YKFSCardEstablishContext(YKF_SCARD_SCOPE_USER, nil, nil, &context)
    
if result != YKF_SCARD_S_SUCCESS {
    print("Could not establish a context.")
    return
}
    
/*
 2. Get the readers and check for key presence. There is only one in this case.
 */
    
// Ask for the readers length.
var readersLength: UInt32 = 0

result = YKFSCardListReaders(context, nil, nil, &readersLength)
if result != YKF_SCARD_S_SUCCESS || readersLength == 0 {        
    if result == YKF_SCARD_E_NO_READERS_AVAILABLE {
        print("Could not ask for readers length. The key is not connected.")
    } else {
        print("Could not ask for readers length (\(result)).")
    }
    
    YKFSCardReleaseContext(context)
    return
}
    
// Allocate the right buffer size and get the readers.
let readers = UnsafeMutablePointer<Int8>.allocate(capacity: Int(readersLength))
result = YKFSCardListReaders(context, nil, readers, &readersLength)
    
if result != YKF_SCARD_S_SUCCESS {        
    if result == YKF_SCARD_E_NO_READERS_AVAILABLE {
        print("Could not list the readers. The key is not connected.")
    } else {
        print("Could not list the readers (\(result)).")
    }
    
    YKFSCardReleaseContext(context)
    return
}
print("Reader \(String(cString: readers)) connected.")
    
readers.deallocate()
    
// Get the status
var readerState = YKF_SCARD_READERSTATE()
readerState.currentState = YKF_SCARD_STATE_UNAWARE
    
result = YKFSCardGetStatusChange(context, 0, &readerState, 1)
if result != YKF_SCARD_S_SUCCESS {
    print("Could not get the status change (\(result)).")
    
    YKFSCardReleaseContext(context)
    return
}
    
if readerState.eventState & YKF_SCARD_STATE_PRESENT != 0 {
    print("The key is not connected.")
}
    
/*
 3. Connect to the key.
 */
    
var card: Int32 = 0
var activeProtocol: UInt32 = YKF_SCARD_PROTOCOL_T1
    
result = YKFSCardConnect(context, readers, YKF_SCARD_SHARE_EXCLUSIVE, YKF_SCARD_PROTOCOL_T1, &card, &activeProtocol)
    
if result != YKF_SCARD_S_SUCCESS {
    print("Could not connect to the key (\(result)).")
    
    YKFSCardReleaseContext(context)
    return
}
    
/*
 4. Create a reusable buffer.
 */
let transmitRecvBufferMaxSize: UInt32 = 258;
let transmitRecvBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(transmitRecvBufferMaxSize))
var transmitRecvBufferLength: UInt32 = transmitRecvBufferMaxSize
    
/*
 5. Send a command.
 */
    
let command: [UInt8] = [0x00, 0xA4, 0x04, 0x00, 0x05, 0xA0, 0x00, 0x00, 0x03, 0x08]
    
result = YKFSCardTransmit(card, nil, command, UInt32(selectPIVCommand.count), nil, transmitRecvBuffer, &transmitRecvBufferLength)
    
if result != YKF_SCARD_S_SUCCESS {
    print("Could not execute the command (\(result)).")
    
    YKFSCardReleaseContext(context)
    return
} else {
    // Handle the response
}
    
/*
 6. Clear buffers and release the context.
 */
    
transmitRecvBuffer.deallocate()
YKFSCardReleaseContext(context)
```

<a name="integration_steps_3_6"></a>
#### 2.3.6 FIDO2 operations with the YubiKey 5Ci 

The FIDO2 Authentication Standard is the most recent set of specifications from the FIDO Alliance. FIDO2 includes more specifications:

- The communication between the client (native application, browser, etc.) and the server is described by the [WebAuthN specifications](https://www.w3.org/TR/webauthn).
- The communication between the client and the authenticator (e.g. YubiKey) is described by the [CTAP2 protocol](https://fidoalliance.org/specs/fido-v2.0-id-20180227/fido-client-to-authenticator-protocol-v2.0-id-20180227.html) (Client To Authenticator Protocol version 2). YubiKit provides the functionality for talking CTAP2 with the YubiKey 5Ci.

The goal of this documentation is not to provide a full explanation of FIDO2 but to explain how to use the FIDO2 functionality with YubiKit and the YubiKey 5Ci. For a more detailed explanation of FIDO2 you are encouraged to access the resources from Yubico developer website.

The FIDO2 standard is very similar to FIDO U2F. FIDO2 is an evolution of the FIDO U2F, which allows for more flexibility and customisation. Some of the most important differences are:

- The possibility to store the credential keys on the device (called *resident keys*). U2F allows only for derived keys.
- FIDO2 adds the possibility to ask for *user verification* (PIN, biometric, etc.) and for *user presence* (usually touch). U2F requires only user presence.
- In FIDO2, a service which wants to create a credential (a Relying Party) can specify RSA keys for the credential. In U2F only ECC keys can be generated.
- When creating a new credential on the key, an exclude list can be specified to avoid creating multiple credentials with the same key.

Like in FIDO U2F, the FIDO2 operations can be logically separated in 3 steps:

1. The application is requesting from the authentication server (WebAuthN server) some information which is required by the YubiKey to perform the operation (creating a credential or requesting an assertion).
2. The application is sending that information to the YubiKey and waits for a result.
3. The application sends the result to the authentication server to be validated.

Steps [1] and [3] are custom to each application. These usually involve some HTTPS calls to the server infrastructure used by the application to get and send data back. The second step is where the application is using YubiKit and the YubiKey.

YubiKit provides FIDO2 support through a single shared instance, `fido2Service` (of type `YKFKeyFIDO2Service`) which is a property of `YKFKeySession`. The FIDO2 service behaves in a similar way with the other services from the key session. It will receive requests and dispatch them asynchronously to be executed by the key. The FIDO2 service is available only when the key is connected to the device and there is an opened session with the key. If the key session is closed or the key is disconnected the `fido2Service` property is nil. 

The `sessionState` property on the key session can be observed to check the state of the session and take appropriate actions to update the UI or to send requests to the key. Because the KVO code can be verbose, a complete example on how to observe this property is provided in the demo application and not here. When the host application prefers a delegate pattern to observe this property, the Demo application provides an example on how to isolate the KVO observation into a separate class and use a delegate to update about changes. The example can be found in the `Examples/Observers` project group.

To get a description of the authenticator, the `YKFKeyFIDO2Service` provides the `[executeGetInfoRequestWithCompletion:]` method which is a high level API for the CTAP2 `authenticatorGetInfo` command. This information can be requested as follows:

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...

YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.keySession.fido2Service;
if (!fido2Service) {
    return;
}

[fido2Service executeGetInfoRequestWithCompletion:^(YKFKeyFIDO2GetInfoResponse *response, NSError *error) {
    if (error) {
        // Handle the error
        return;
    }        
    // Handle the response
}];
```

##### Swift

```swift
let keySession = YubiKitManager.shared.keySession
    
guard let fido2Service = keySession.fido2Service else {
    return
}

fido2Service.executeGetInfoRequest { (response, error) in
    guard error == nil else {
        // Handle the error here.
        return
    }
    // Handle the response here.   	     
}
```

A new FIDO2 credential can be created by calling `[executeMakeCredentialRequest:completion:]` on the FIDO2 service. The following code will create a new credential with a non-resident ECC key:
 
##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...

// Not a resident key and no PIN required.
NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2MakeCredentialRequestOptionRK: @(NO),
                                        YKFKeyFIDO2MakeCredentialRequestOptionUV: @(NO)};
NSInteger alg = YKFFIDO2PublicKeyAlgorithmES256;
	
YKFKeyFIDO2MakeCredentialRequest *makeCredentialRequest = [[YKFKeyFIDO2MakeCredentialRequest alloc] init];
    
// Some example data as a hash.
UInt8 *buffer = malloc(32);
if (!buffer) {
    return;
}
memset(buffer, 0, 32);
NSData *data = [NSData dataWithBytes:buffer length:32];
free(buffer);
    
// Set the request clientDataHash.
makeCredentialRequest.clientDataHash = data;
    
// Set the request rp.
YKFFIDO2PublicKeyCredentialRpEntity *rp = [[YKFFIDO2PublicKeyCredentialRpEntity alloc] init];
rp.rpId = @"yubico.com";
rp.rpName = @"Yubico";
makeCredentialRequest.rp = rp;
    
// Set the request user.
YKFFIDO2PublicKeyCredentialUserEntity *user = [[YKFFIDO2PublicKeyCredentialUserEntity alloc] init];
user.userId = data;
user.userName = @"john.smith@yubico.com";
user.userDisplayName = @"John Smith";
makeCredentialRequest.user = user;
    
// Set the request pubKeyCredParams.
YKFFIDO2PublicKeyCredentialParam *param = [[YKFFIDO2PublicKeyCredentialParam alloc] init];
param.alg = alg;
makeCredentialRequest.pubKeyCredParams = @[param];
    
// Set the request options.
makeCredentialRequest.options = makeCredentialOptions;
    
YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.keySession.fido2Service;
if (!fido2Service) {
    return;
}

[fido2Service executeMakeCredentialRequest:makeCredentialRequest completion:^(YKFKeyFIDO2MakeCredentialResponse *response, NSError *error) {
    if (error) {
        // Handle the error here.        
        return;
    }
    // Handle the response here.
}];
```

##### Swift

```swift
// Not a resident key and no PIN required.
let makeCredentialOptions = [YKFKeyFIDO2MakeCredentialRequestOptionRK: false, 
								  YKFKeyFIDO2MakeCredentialRequestOptionUV: false]	
let alg = YKFFIDO2PublicKeyAlgorithmES256
	
guard let fido2Service = YubiKitManager.shared.keySession.fido2Service else {           
    return
}
            
let makeCredentialRequest = YKFKeyFIDO2MakeCredentialRequest()
    
// Some example data as a hash.	    
let data = Data(repeating: 0, count: 32)
makeCredentialRequest.clientDataHash = data
    
// Set the request rp.
let rp = YKFFIDO2PublicKeyCredentialRpEntity()
rp.rpId = "yubico.com"
rp.rpName = "Yubico"
makeCredentialRequest.rp = rp
  
// Set the request user.  
let user = YKFFIDO2PublicKeyCredentialUserEntity()
user.userId = data
user.userName = "john.smith@yubico.com"
user.userDisplayName = "John Smith"
makeCredentialRequest.user = user
	
// Set the request pubKeyCredParams.
let param = YKFFIDO2PublicKeyCredentialParam()
param.alg = alg
makeCredentialRequest.pubKeyCredParams = [param]
  
// Set the request options.
makeCredentialRequest.options = makeCredentialOptions
     
fido2Service.execute(makeCredentialRequest) { (response, error) in
    guard error == nil else {
        // Handle the error
        return
    }
    // Handle the response
}
```
	
In FIDO2, during the authentication phase, the Relying Party will ask from the user to approve and provide an assertion from the authenticator (in this case the YubiKey5Ci), after the authenticator was registered as a 2FA method. YubiKit provides the `[executeGetAssertionRequest:completion:]` method on the `YKFKeyFIDO2Service`, which allows to retrieve an assertion from the key:

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
	
YKFKeyFIDO2GetAssertionRequest *getAssertionRequest = [[YKFKeyFIDO2GetAssertionRequest alloc] init];
    
NSDictionary *assertionOptions = @{YKFKeyFIDO2GetAssertionRequestOptionUP: @(YES),
                                  YKFKeyFIDO2GetAssertionRequestOptionUV: @(NO)};

// Some example data as a hash.	        
UInt8 *buffer = malloc(32);
if (!buffer) {
    return;
}
memset(buffer, 0, 32);
NSData *data = [NSData dataWithBytes:buffer length:32];
free(buffer);

getAssertionRequest.rpId = @"yubico.com";
getAssertionRequest.clientDataHash = data;
getAssertionRequest.options = assertionOptions;
	
// Set the credential to get the assertion for.
YKFFIDO2PublicKeyCredentialDescriptor *credentialDescriptor = [[YKFFIDO2PublicKeyCredentialDescriptor alloc] init];
	
// This credential ID was generated by the key when the credential was added/registered.
// The RP should store this and provide this back to the client during authentication.
credentialDescriptor.credentialId = <credential ID>;
    
YKFFIDO2PublicKeyCredentialType *credType = [[YKFFIDO2PublicKeyCredentialType alloc] init];
credType.name = @"public-key";
credentialDescriptor.credentialType = credType;
    
getAssertionRequest.allowList = @[credentialDescriptor];
	
// Execute the Get Assertion request.
	
YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.keySession.fido2Service;
if (!fido2Service) {
    return;
}
[fido2Service executeGetAssertionRequest:getAssertionRequest completion:^(YKFKeyFIDO2GetAssertionResponse * response, NSError *error) {
    if (error) {
        // Handle the error		
        return;
    }	
    // Handle the response	  
}];
```

##### Swift

```swift
let assertionOptions = [YKFKeyFIDO2GetAssertionRequestOptionUP: true,
                       YKFKeyFIDO2GetAssertionRequestOptionUV: false]

let getAssertionRequest = YKFKeyFIDO2GetAssertionRequest()
    
getAssertionRequest.rpId = "yubico.com"
getAssertionRequest.clientDataHash = data
getAssertionRequest.options = assertionOptions
    
let credentialDescriptor = YKFFIDO2PublicKeyCredentialDescriptor()
	
// This credential ID was generated by the key when the credential was added/registered.
// The RP should store this and provide this back to the client during authentication.
credentialDescriptor.credentialId = <credential ID>
	
let credType = YKFFIDO2PublicKeyCredentialType()
credType.name = "public-key"
credentialDescriptor.credentialType = credType
getAssertionRequest.allowList = [credentialDescriptor]

// Execute the Get Assertion request.
	
guard let fido2Service = YubiKitManager.shared.keySession.fido2Service else {
    return
}
fido2Service.execute(getAssertionRequest) { (response, error) in
    guard error == nil else {
        // Handle the error
        return
    }
    // Handle the response
}
```

The FIDO2 standard defines the ability to set a PIN on the authenticator. In this way an additional level of security can be enabled for certain operations with the key. By default the YubiKey has no PIN set on the FIDO2 application. The PIN can be any alphanumeric combination (between 4 and 255 UTF8 encoded characters). Once the PIN is set on the FIDO2 application, it can be only changed but not removed. The only way to remove the PIN is by resetting the FIDO2 application. Keep in mind that the Reset operation is destructive and all the keys will be removed as well.

The most common scenario, where PIN verification is required, happens when adding a new credential to the key. This operation requires more privileges so the YubiKey will ask for PIN verification, if any PIN was set on the FIDO2 application.

When the key requires PIN verification for an operation, YubiKit will return the error code `YKFKeyFIDO2ErrorCode.PIN_REQUIRED`. In this particular scenario the application can cache the request, perform the PIN verification and retry the request. This flow is implemented in the `FIDO2ViewController`. 

To verify the PIN, the FIDO2 Service provides the `[executeVerifyPinRequest:completion:]` method:

##### Objective-C

```objective-c
YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.keySession.fido2Service;
if (!fido2Service) {
    // The session with the key is closed
    return;
}
    
NSString *pin = @"some value";
YKFKeyFIDO2VerifyPinRequest *verifyPinRequest = [[YKFKeyFIDO2VerifyPinRequest alloc] initWithPin:pin];
if (!verifyPinRequest) {
    // The PIN is empty
    return;
}
    
[fido2Service executeVerifyPinRequest:verifyPinRequest completion:^(NSError *error) {
    if (error) {
        // The key failed to process the request or the PIN was invalid.
        // Check the error code and the description to see the reason.
        return;
    }
    // The PIN verification was successful. Proceed with the other requests.
}];
```

##### Swift

```swift
let keySession = YubiKitManager.shared.keySession
guard let fido2Service = keySession.fido2Service else {
    // The session with the key is closed
    return
}
    
let pin = "some value"
guard let verifyPinRequest = YKFKeyFIDO2VerifyPinRequest(pin: pin) else {
    // The PIN is empty
    return
}
fido2Service.execute(verifyPinRequest) { (error) in
    guard error == nil else {
        // The key failed to process the request or the PIN was invalid.
        // Check the error code and the description to see the reason.
        return
    }
    // The PIN verification was successful. Proceed with the other requests.
}
```

YubiKit provides also the ability set and change the PIN. The requests are very similar to the PIN verification and a complete example is implemented in the YubiKit Demo application, `FIDO2DemoViewController`.

---

**Important Notes:**

1. After PIN verification, YubiKit will automatically append the required PIN auth data to the FIDO2 requests when necessary. YubiKit does not cache any PIN. Instead it's using a temporary shared token, which was agreed between the key and YubiKit as defined by the CTAP2 specifications. This token is valid as long the session is opened and it's not persistent.

2. After verifying the PIN and executing the necessary requests with the key, the application can clear the shared token cache by calling `[clearUserVerification]` on the FIDO2 Service. This will also happen when the key is unplugged from the device or when the session is closed programatically.

3. After changing the PIN, a new PIN verification is required. 

---

The YubiKit Demo application provides detailed demos on how to use the FIDO2 functionality of the library: 

- The `FIDO2 Demo` in the Other demos provides a self-contained demo for the requests discussed in this section and more details about the API. 

- The demo available in the FIDO2 tab of the application provides a complete example on how YubiKit can be used together with a WebAuthN server to register and authenticate. 

<a name="customising_yubikit"></a>
### 3. Customising YubiKit 

YubiKit allows customising some of its behaviour by using `YubiKitConfiguration` and `YubiKitExternalLocalization`.

For providing localised strings for the user facing messages shown by the library, YubiKit provides a collection of properties in `YubiKitExternalLocalization`.

One example of a localised string is the message shown in the NFC scanning UI while the device waits for a YubiKey to be scanned. This message can be localised by setting the value of `nfcScanAlertMessage`:

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
NSString *localizedAlertMessage = NSLocalizedString(@"NFC_SCAN_MESSAGE", @"Scan your YubiKey.");
YubiKitExternalLocalization.nfcScanAlertMessage = localizedNfcScanAlertMessage;
```
	
##### Swift

```swift
let localizedAlertMessage = NSLocalizedString("NFC_SCAN_MESSAGE", comment: "Scan your YubiKey.")
YubiKitExternalLocalization.nfcScanAlertMessage = localizedAlertMessage
```

For all the available properties and their use look at the code documentation for `YubiKitExternalLocalization`.

---

**Note:**
`YubiKitExternalLocalization` provides default values in English (en-US), which are useful only for debugging and prototyping. For production code always provide localised values.

---

In some conditions the NDEF payload format from a YubiKey can be modified and may have a custom way of appending metadata (as Text or URI) to the OTP token. In such a scenario, when the payload has a complex or non-standard format, the library allows the host application to provide a custom parser for the payload. 

The YubiKey can append two types of metadata to the OTP token: **Text** or **URI** (default one). To provide custom parsers the host application can use `YKFOTPURIParserProtocol` for a custom URI Parser and `YKFOTPTextParserProtocol` for a custom text parser. The code level documentation provides additional details on what the parsers should implement.

Here is an example of how to set a custom URI parser:

##### Objective-C
	
```objective-c	
#import <YubiKit/YubiKit.h>
...	
@interface CustomURIParser: NSObject<YKFOTPURIParserProtocol>
@end
	
@implementation CustomURIParser
    // Custom parser implementation
@end	
...
YubiKitConfiguration.customOTPURIParser = [[CustomURIParser alloc] init];
```

##### Swift

```swift
class CustomURIParser: YKFOTPURIParserProtocol {    
    // Custom parser implementation
}
...
YubiKitConfiguration.customOTPURIParser = CustomURIParser()
```

<a name="using_demo"></a>
## 4. Using the demo application

The library comes with a demo application named **YubiKitDemo**. The application is implemented in Swift 5 (Xcode 10.2) and it shows a complete example on how to use the library. 

The YubiKit Demo application shows how the library is linked with a project so it can be used for a side-by-side comparison when adding the library to another project.

YubiKit headers are documented and the documentation is available ether by reading the header file or by using the QuickHelp from Xcode (Option + Click symbol). Use this documentation for a more detailed explanation of all the methods, properties and parameters from the API.

<a name="appstore_publishing"></a>
## 5. Publishing on AppStore 

Before publishing on AppStore there are a few additional steps required when using YubiKit. 

When using only the NFC functionality to read OTPs, there are no additional requirements from Apple prior to publish the application on AppStore. 

When communicating with a YubiKey with lightning connector, the application will communicate with an external accessory. Apple requires from the manufacturer of the accessory (in this case Yubico) to provide a list of applications which can talk to the accessory over the iAP2 custom protocol (for the YubiKey the iAP2 protocol is called **com.yubico.ylp**). This process is called **Application Whitelisting**. The process involves adding the application *Bundle ID* to a list of allowed applications which can communicate with the YubiKey. This whitelisting has to be completed before submitting the application for an AppStore review because the AppStore reviewers will verify it. For more details about this process contact Yubico.

If the application was not submitted for an AppStore review (the application is still in development), there is no need to whitelist it before starting the development. If the [integration steps](#integration_steps) are correctly followed, the application can communicate with the YubiKey.

In case of applications signed with an Enterprise Distribution certificate (applications distributed within an organisation), the application whitelisting is not required but is strongly recommended. In the [Apple Developer Enterprise Program License Agreement](https://developer.apple.com/services-account/download?path=/Documentation/License_Agreements__Apple_Developer_Enterprise_Program/Apple_Developer_Enterprise_Program_License_Agreement_20181019.pdf), section 6.2 (Internal Use Applications used by Permitted Users and Customers), Apple reserves the right to review the application, so having the application whitelisted is important.

<a name="faq"></a>
## 6. FAQ

#### Q1. Does YubiKit store any data on the device?

Yubikit doesn't store any data locally on the device. This includes NSUserDefaults, application sandbox folders and Keychain. All the data required to perform an operation is stored in memory for the duration of the operation and then discarded.

#### Q2. Does YubiKit communicate with any services?

Yubikit doesn't communicate with any services, like web services or other type of network communication. YubiKit is a library for sending, receiving and processing the data from a YubiKey.

#### Q3. Can I use YubiKit with other devices which are not from Yubico?

YubiKit is a library which should be used only to interact with a device manufactured by Yubico. While some parts of it may work with other devices, the library was developed and tested to work with YubiKeys. When attaching a lightning device, YubiKit will always check if the manufacturer of the device is Yubico before connecting to it.

#### Q4. Is YubiKit compiled with support for Bitcode and Position Independent code?

Yes, YubiKit is compiled to accommodate any modern iOS project. The supplied library is compiled with Position Independent code and Bitcode. The release version of the library is optimised (Fastest, Smallest).

#### Q5. Is YubiKit logging or asserting in release mode?

No, YubiKit is not logging in release mode. The logs from YubiKit will show only in debug builds to help the developer to see what YubiKit does. The same stands for assertions. YubiKit will assert in debug mode to warn the developer when invalid parameters are passed to the library or when something unexpected happened with the key. In release, the library will handle invalid states in different ways (e.g. returning nil if the object was not properly initialised, returning errors, etc.).

#### Q6. Are there any versions of iOS where YubiKit does not work?

YubiKit should work on any modern version of iOS (10, 11 and 12) with a few exceptions\*. It's recommended to always ask the users to upgrade to the latest version of iOS to protect them from known, old iOS issues. Supporting the last 2 version of iOS (n and n-1) is usually a good practice to keep the old versions of iOS out. According to [Apple statistics](https://developer.apple.com/support/app-store/), ~90-95% of all iOS devices run the latest 2 versions of iOS because upgrading the OS is free and Apple usually provides a device with upgrades for 5 years.

\* Some versions of iOS had bugs affecting all accessories communicating over lightning. iOS 11.2 was one of them where the applications could not communicate with lightning accessories due to some bugs in the XPC communication. The bug was fixed by Apple in iOS 11.2.6. For these reasons it's recommended to take in consideration rare but possible iOS bugs when designing the application. 

#### Q7. How can I debug the application while using a YubiKey with lightning connector?

Starting from Xcode 9, the IDE provides the ability to debug the application wirelessly. In this way the physical connector is not used for connecting the device to the computer, for debugging the application. This [WWDC session](https://developer.apple.com/videos/play/wwdc2017/404/) explains the wireless debugging functionality in Xcode.

#### Q8. What is the PIV attestation certificate of the YubiKey?

The PIV attestation certificate is published [here](https://developers.yubico.com/PIV/Introduction/piv-attestation-ca.pem), on Yubico Developers website.

<a name="additional_resources"></a>
## 7. Additional resources

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