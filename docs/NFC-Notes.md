# YubiKit 3.0.0 - NFC Notes

See [**Changelog**](./Changelog.md) for a general list of changes made since the last release.
This document is intended to cover the changes made to the YubiKit for iOS to support NFC (added in YubiKit 3.0.0) and what you need to know when integrating your app with the YubiKit SDK to support NFC-Enabled YubiKeys.

## 1. Adding FIDO support for NFC YubiKeys

To add support for NFC YubiKeys in your application, follow these steps:

- Add a `NEW` entitlement for reading NFC specific tags, available since iOS 13. This new entitlement is added automatically by Xcode when enabling the **Near Field Communication Tag Reading** capability in the target **Signing & Capabilities**. After enabling the capability the *.entitelments* files needs to contain the `NDEF` and `TAG` formats:

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
    <string>A000000527200101</string> // YubiKey application/OTP AID
</array>
</plist>
```

- The *Info.plist* also needs to include a privacy description for NFC usage, using the **NFCReaderUsageDescription** key:

```xml
<key>NFCReaderUsageDescription</key>
<string>The application needs access to NFC reading to communicate with your YubiKey.</string>
```

## 2. FIDO over NFC

Using the FIDO APIs over the NFC session is identical to using the APIs over the accessory (used for the YubiKey 5Ci as an MFi accessory) session. The application builds the requests in the same way and the application can choose to execute requests over the *accessory* or the *NFC* session:

```swift
var fido2Service: YKFFIDO2ServiceProtocol? = nil

// #1 Use the fido2Service instance from the accessory session              
fido2Service = YubiKitManager.shared.accessorySession.fido2Service

// #2 Use the fido2Service instance from the NFC session
fido2Service = YubiKitManager.shared.nfcSession.fido2Service   

...

fido2Service.execute(makeCredentialRequest) { [weak self] (response, error) in
    ...
}
```

The FIDO2 demo from the [YubiKit Demo](./YubiKitDemo) application has a complete example of how to use both sessions (accessory & NFC) to register a new account and authenticate with the Yubico Demo WebAuthn Server.

## 3. Refactoring Changes [2.0.0 -> 3.0.0-Preview1]

To accommodate the presence of another transport, YubiKit was refactored internally to reuse as much as possible from the existing YubiKit 2.0.x stack. However, some of the refactoring touched the interface of the library, but only in a minimal way.

#### Change #1 - YKFSession

The `YKFSession` was renamed `YKFAccessorySession`. Before adding support for ISO 7816 Tags, introduced in iOS 13, the only way to execute requests against a security key was to use the YubiKey 5Ci over iAP2 protocol when connected via the Lightning connector. This was the only *key* supported by the library, hence the name `YKFSession`. Now the name of the session better reflects the transport of the session and it's consistent with `YKFNFCSession`. If the `keySession` was used by the application to execute requests against the YubiKey 5Ci, the call:

```swift
YubiKitManager.shared.keySession.[u2fService/fido2Service/..].execute..
```
 
becomes

```swift        
YubiKitManager.shared.accessorySession.[u2fService/fido2Service/..].execute..
```

**If you observe the changes in the session state, make sure to update the observations as well.**

#### Change #2 - YKFNFCSession

The `YKFNFCSession` is a collection of services similar to the `YKFAccessorySession`. The legacy OTP scanning interface was unchanged and moved into a separate service called `YKFNFCOTPService`. If the OTP scanning with version 2.0.x was used, the call: 
    
```swift
YubiKitManager.shared.nfcSession.requestOTPToken...
```
    
becomes

```swift        
YubiKitManager.shared.nfcSession.otpService.requestOTPToken...
```

#### Change #3 - Other

- The `YKFNFCReadError` was renamed `YKFNFCError`, so it's no longer specific to the *read* operations.
- The `YKFDescription` was renamed `YKFAccessoryDescription`.

