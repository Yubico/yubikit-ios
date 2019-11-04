# YubiKit 3.0.0 Beta 1 - NFC Notes

- The YubiKit 3.0.0 Beta 1 adds support for ISO 7816 tags which allows the application to use the FIDO functionality of the YubiKey over NFC, on iOS 13 or newer. 

- The FIDO2 protocol is supported by the YubiKey 5 NFC. To use the FIDO2 demo from YubiKit Demo application, you need to be in possession of a YubiKey 5 NFC.

- To use YubiKit 3.0.0 Beta 1, the application needs to be compiled with Xcode 11 GM or newer (iOS 13 SDK).



## 1. Adding FIDO support for NFC YubiKeys

To add support for NFC YubiKeys in the application follow these steps:

- Add a new entitlement for reading application specific tags, available from iOS 13. This new entitlement is added automatically by Xcode when enabling the **Near Field Communication Tag Reading** capability in the target **Signing & Capabilities**. After enabling the capability the *.entitelments* files needs to contain this:

```xml
...
<dict>
	<key>com.apple.developer.nfc.readersession.formats</key>
	<array>
		<string>NDEF</string> // NDEF Tag, available since iOS 11
		<string>TAG</string>  // Application specific tag, including ISO 7816 Tags
	</array>
</dict>
...
```

- The application needs to define the list of `application IDs` or `AIDs` it can connect to, in the *Info.plist* file. The `AID` is a way of uniquely identify an application on a ISO 7816 tag, which is usually defined by a standard. FIDO2 and U2F use the AID `A0000006472F0001` on any FIDO compliant NFC key, including the YubiKey. After adding the list of supported AIDs, the Info.plist entry should look like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>A000000527471117</string> // YubiKey Management Application AID
	<string>A0000006472F0001</string> // FIDO AID
</array>
</plist>
```

- The *Info.plist* needs to include also a privacy description for NFC usage, using the **NFCReaderUsageDescription** key:

```xml
<key>NFCReaderUsageDescription</key>
<string>The application needs access to NFC reading to communicate with your Yubikey.</string>
```

## 2. FIDO over NFC

Using the FIDO APIs over the NFC session is identical with using the APIs over the accessory session. The application builds the requests in the same way and can choose to execute them over the accessory or the NFC session:

```swift
var fido2Service: YKFKeyFIDO2ServiceProtocol? = nil

// #1 Use the fido2Service instance from the accessory session              
fido2Service = YubiKitManager.shared.accessorySession.fido2Service

// #2 Use the fido2Service instance from the NFC session
fido2Service = YubiKitManager.shared.nfcSession.fido2Service   

...

fido2Service.execute(makeCredentialRequest) { [weak self] (response, error) in
    ...
}
```

The FIDO2 demo from YubiKit Demo application has a complete example of how to use both sessions to register a new account and authenticate with the Yubico Demo website.

## 3. Refactoring Notes [2.0.0 -> 3.0.0]

To accommodate the presence of another transport, YubiKit was refactored internally to reuse as much as possible from the existing stack from YubiKit 2.0.0. However some of the refactoring touched the interface of the library, but only in a minimal way.

#### Note #1 - YKFKeySession


The `YKFKeySession` was renamed `YKFAccessorySession`. Before the support for ISO 7816 Tags, introduced in iOS 13, the only way to execute requests against the key was to use the YubiKey 5Ci, over iAP2. This was the only *key* supported by the library, hence the name `YKFKeySession`. Now the name of the session reflects better the transport of the session and it's consistent with `YKFNFCSession`. If the `keySession` was used by the application to execute requests against the key, the call:

```swift
YubiKitManager.shared.keySession.[u2fService/fido2Service/..].execute..
```
 
becomes

```swift        
YubiKitManager.shared.accessorySession.[u2fService/fido2Service/..].execute..
```

**If you observe the changes in the session state make sure to update the observations as well.**

#### Note #2 - YKFNFCSession

The `YKFNFCSession` is a collection of services similar with the `YKFAccessorySession`. The OTP scanning interface was moved, unchanged, into a separate service: `YKFNFCOTPService`. On the application level, if the OTP scanning with version 2.0.0 is used, the call: 
    
```swift
YubiKitManager.shared.nfcSession.requestOTPToken...
```
    
becomes

```swift        
YubiKitManager.shared.nfcSession.otpService.requestOTPToken...
```

#### Note #3 - Other

- The `YKFNFCReadError` was renamed `YKFNFCError`, so it's no longer specific to the *read* operations.
- The `YKFKeyDescription` was renamed `YKFAccessoryDescription`.

