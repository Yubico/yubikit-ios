# YubiKit Changelog

## 4.3.0

- Added USC-C support on iPads running iPadOS 16 using TKSmartCard.
- Added support for using access key for YKFOATHSession.
- Improved OATH error handling when saving a new account.
- Colon character no longer allowed in OATH issuer.
- More validation options when creating a YKFOATHCredentialTemplate.
- didFailConnectingNFC will no longer be called if the connection was closed by calling stopNFCConection().
- Fixes issue where wrong error type was returned in various parts of the SDK.
- YKFAccessoryConnection.accessoryDescription is no longer marked as deprecated.

## 4.2.0

- Fixed calculation of non-truncated HMAC signatures in OATH.
- Fixed crash on iOS 15 when scanning OTP over NFC.
- CoreNFC specified as weak framework fixing crash on devices not supporting NFC.
- Fixed broken header file imports for static compiled libraries.
- Bug fixes for PIN handling in FIDO2.
- Replaced TKBERTLVRecord from CryptoTokenKit with own BERTLV implementation. This fixes issues on older iOS versions.

## 4.1.0

- Optional timestamp parameter added to OATH calculate and calculateAll methods.
- Firmware version is now a public variable on `YKFManagementSession`.
- If a connection is already present when setting the `YKFManagerDelegate` it will return that connection immideatly.
- Extra dot at the end of `YKFVersion` string removed.
- Fixed memory issues where we retained the `YKFManagerDelegate`.
- Fixed issue where failing to unlock a key with passcode before sending an OATH command got the session in a non recoverable state.
- Improved control over the messages displayed in the NFC dialog.
- Added `- (void)dispatchBlockOnCommunicationQueue:(YKFConnectionControllerCommunicationQueueBlock)block` to `YKFConnectionControllerProtocol` that will run a block after all enqueued commands has finished.
- Improved error handling in OATH session.
- More robust algorithm comparison in PIV session.
- Fixed bug where an auth required error was sent instead of touch timeout in OATH session.
- Fixed bug where the number of OATH accounts you could read was limited to around 8
- Added new optional connection delegate method that will signal if the NFC dialog was cancelled by the user or timed out.
- Swift package manager header files exluded from Cocoapod distribution.
- Various array out of bounds checks
- Improved error checks
- Fixes bug where authenticateWithManagementKey in the YKFPIVSession would fail to call its completion handler upon failure.
- Fixes broken implementation of non truncated OATH codes

## 4.0.0

This release breaks backwards compatibility with previous versions of the SDK. The reason for this is to make the SDK easier to
integrate and also align better with Yubico's other SDKs in regards of naming conventions and concepts. Read the
[transition guide](./docs/transitioning-sdk-4.md) for more details.

- Replaced KVO with a delegate protocol for monitoring changes in the YubiKey connection status.

- `YKFNFCConnection` and `YKFAccessoryConnection` now represent the NFC and Accessory connections to the YubiKey.

- The two `YKFConnections` provide the different `YKFSessions` used to communicate with the applications on
    the YubiKey, i.e `YKFOATHSession`, `YKFPIVSession`.

- Replaced `YKFRawCommandService` with `YKFSmartCardInterface`, which adds functionality for automatically handling multipart 
  responses from the YubiKey and improves error handling.

- Added `YKFPIVSession` which allows the  SDK to easily communicate with the PIV application on the YubiKey.

- Rewrote the full stack tests to provide greater test coverage and a [good source of sample code](./YubiKitTests/Tests/).

- iOS deployment target bumped to 11.

- `YKFPCSC` and `YKFPCSCLayer` marked for future deprecation.
---

## 3.2.0

- Support for Swift Package Manager

- Added support for renaming OATH credentials (supported by Yubikeys from version 5.3.1)

- iPad Pro 4 and iPad Air with USB-C now correctly reports its capabilities in the SDK

- Improved Base32 decoding
---

## 3.1.0

- Raw commands service `YKFRawCommandService` now allows to specify timeouts on each command using `YKFCommandConfiguration` in case if user wants to speed up communication with YubiKey or getting timeouts on execution of specific command. 

- Reduced default timeout between sending command to YubiKey and receiving response from YubiKey in order to be more performant over Lightning.

- This SDK version now provides  `YKFChallengeResponseService` which allows to calculate HMAC-SHA1 on pre-programmed YubiKey. Read more about usage of [Challenge-response](./docs/chr.md)

- Added `YKFManagementService` which allows to check whether application is available on YubiKey. And can enable or disable interfaces/application on YubiKey (if they are available). Read more about usage of [management service](./docs/mgmt.md)

- Fixes OATH credential parser for credentials that contain "\" or ":". 

- Added `YKFOATHService` method `selectOATHApplication` that provides response on selection of OATH applet. It contains firmware version which can be used as one of the methods to detect firmware version over NFC.

- Improvements in YubiKitDemo application: U2F and FIDO2 in Other demo section now support NFC-Enabled YubiKeys.
---

## 3.0.0

- Improvements to NFC API: ability to customize NFC alert message at any point of time it's visible, an error in case if NFC session was closed without successful invalidation (including cancellation), allows to handle multiple tags during one open nfc session and do not close session if key was removed from NFC reader.

- Added ability for application to subscribe for logger events and customize/create it's own logger (e.g. sent logs to the file)
---

## 3.0.0-Preview2

- Adds support for OATH protocol over NFC on devices running iOS 13 or newer. Also wraps and simplifies raw APDU communication with NFC-Enabled YubiKeys.
---

## 3.0.0-Preview1

`BREAKING CHANGES`: 
- See `Refactoring Changes` section under [NFC-Notes](./docs/NFC-Notes.md)

---

- This version now supports NFC-Enabled YubiKeys for FIDO2. `Note`: All NFC capabilities (except Yubico OTP) require iOS 13+ on the user's device. See [NFC-Notes.md](./docs/NFC-Notes.md) for more details on the addition of NFC support and notable changes to the key sessions.

- The YubiKit 3.0.0-Preview1 adds support for ISO 7816 tags which allows your application to use the FIDO2 functionality of the YubiKey over NFC on devices running iOS 13 or newer. 

- The FIDO2 protocol implementation now supports any NFC-Enabled YubiKey, in addition to the YubiKey 5Ci. The library provides examples for implementing FIDO2 over an accessory (YubiKey 5Ci) or NFC. In addition, the [YubiKit Demo](./YubiKitDemo/README.md) application provides an end-to-end solution for both protocols.

- To use YubiKit 3.0.0-Preview1, the application needs to be compiled with Xcode 11 or newer (iOS 13 SDK).

---

## 2.0.1

- Fixed an edge case for CCID when the WTX responses are concatenated with the payload. This issue mostly affects the calculation of OATH credentials with touch.

- Added the possibility to attach a custom application logger to process the library logs. For more details check the `Examples/CustomLogger` in the YubiKit Demo application. 

- Several other improvements to OATH, including the possibility to create OATH credentials without issuer and the ability to read and add credentials with 7 digits.

---

## 2.0.0

- The internal CBOR encoder used by the FIDO2 API is now sorting the map keys according to canonical CBOR rules when the keys are text strings. This fixes a bug with the order of the keys in the `webauthnAttestationObject` returned by the `YKFFIDO2MakeCredentialResponse`.

- Improved the error handling when the applications are disabled on the YubiKey. In case of FIDO (FIDO2 and U2F) the application is shared (the CTAP specifications use the same AID). In this specific scenario, when only one of them is enabled, YubiKit was returning `YKFAPDUErrorCodeInsNotSupported`. Now the library will return `YKFSessionErrorMissingApplicationCode` when trying to use the disabled application, similar with the scenario when both applications are disabled.

- Added a new constant, `YKFFIDO2GetInfoResponseOptionUserVerification`, which can be used to test if the authenticator supports UV (User Verification). Removed from the YubiKit Demo application the explicit set of the UV options flag when creating FIDO2 credentials or getting assertions because the YubiKey 5Ci is not capable of verifying the user within itself. This update is available from firmware version 5.2.x and reflects the latest [CTAP2 specifications](https://fidoalliance.org/specs/fido-v2.0-ps-20190130/fido-client-to-authenticator-protocol-v2.0-ps-20190130.html#authenticatorGetInfo).

- Renamed the `supportsLightningKey` property from `YubiKitDeviceCapabilities` to `supportsMFIAccessoryKey`. The property will also return `NO/false` when the iOS device has an USB-C connector, such as the iPad Pro 3rd generation. These devices do not officially support MFi external accessories.

- Renamed several classes, properties and UI labels in the YubiKit Demo application to not use the term *Lightning*. This change was made to avoid possible trademark issues with this term. 

- Some minor improvements to the PC/SC API to dynamically read some properties, like the name and the model of the key, from the `YKFSession` instead of returning hardcoded values.

- Several OATH improvements, including support for touch credentials and improved compatibility with other libraries/applications which implement the YOATH protocol, such as Yubico Authenticator for Android and desktop.

- Improved the ability to manually build OATH credentials using the `YKFOATHCredential` model provided by the library.

- The `build.sh` script will generate a `release-universal` flavour of the library, together with the previous flavours (`release` and `debug-universal`).

---

## 2.0.0 RC1

- The `YKFFIDO2MakeCredentialResponse` has two new properties: `ctapAttestationObject` and `webauthnAttestationObject`: 
	- The `ctapAttestationObject` is identical to the `rawResponse` from the key. This attestation format follows the [CTAP2 specifications](https://fidoalliance.org/specs/fido-v2.0-ps-20190130/fido-client-to-authenticator-protocol-v2.0-ps-20190130.html#responses) for packing the attestation object from the authenticator. In this format the top level CBOR map is using numeric keys for `authData`, `fmt` and `attStmt`.
	- The `webauthnAttestationObject` is similar with the `ctapAttestationObject`. The only difference is in the top level CBOR map keys which are text, as defined in the [WebAuthN Attestation Object specifications](https://developer.mozilla.org/en-US/docs/Web/API/AuthenticatorAttestationResponse/attestationObject).

- The `attStmt` property from the `YKFFIDO2MakeCredentialResponse` is an opaque object now (NSData/Data) instead of a parsed CBOR map to comply with the CTAP2 specifications on how the clients need to handle this object.

- The **U2F** external accessory protocol support has been removed from both YubiKit and YubiKit Demo application. The library supports from this version only the **com.yubico.ylp** external accessory protocol. Make sure to remove the **U2F** protocol from the application *Info.plist* file before submitting the application for an AppStore review.

- The `YubiKitDeviceCapabilities` contains a new property: `supportsLightningKey`. This property should be used in the application before starting the key session. If the check is not performed, in debug builds the library will assert when trying to start the key session on an unsupported iOS version. This property returns `YES`/`true` when: 
	- the iOS version is iOS 10 or newer.
	- the iOS version is not in a blacklist of versions where the external accessories don't work due to iOS bugs.

- Moved the WebAuthN clientData into the library. The new class provided by the library is called `YKFWebAuthnClientData`. This change avoids duplicate implementations of the Client Data in every application which could lead to different results when using the FIDO2 APIs. When using Swift 5, this change avoids a random memory corruption of the old implementation from the YubiKit Demo application, when creating and passing the data to the library. **Make sure to use the new implementation** if the demo application code was reused.

- Several improvements and bug fixes to the logging of the library in debug builds. The library check in debug builds if the application is configured properly when starting the key session by looking at the application external accessory protocols.

- The firmware version, available in `YKFDescription.firmwareRevision` returns now the format `[major].[minor].[patch]` instead of a number.

- Improvements and bug fixes to the YubiKit Demo application:
	- The `WebAuthnClientData` is using an updated Swift 5 version of `Data.withUnsafeBytes` with the memory bound explicitly specified to avoid some possible data corruption when hashing.
	- Removed a bug in the Other demos, Raw Commands where the logs were wiped immediately after running a demo, if the flow was successful.
	
- Several internal library improvements related to: debug assertions, unit testability and performance.

---

## 2.0.0 B8

- The YubiKit Demo application was updated to Xcode 10.2 and Swift 5. This version (or newer) of Xcode is required to compile and run the application.

- Added support for CTAP2/FIDO2 PIN management, including verification, getting the number of retries, setting and changing the PIN. The FIDO2 requests (`YKFFIDO2MakeCredentialRequest` and `YKFFIDO2GetAssertionRequest`) work with the CTAP2 PIN APIs.

- Replaced the U2F demo tab in the demo application with a new FIDO2/WebAuthN demo. The WebAuthN demo communicates with the Yubico WebAuthN demo website. The U2F demo was moved into a self-contained demo in the Other demos tab.

- The self-contained FIDO2 demo in the Other demos tab provides the ability to manage the PIN.

- The FIDO2 Make Credential and Get Assertion requests return also the raw CBOR response from the key. These responses can be sent directly to the server when the server does the parsing of the payload.

- Added support for CTAP2 Get Next Assertion request.

- Improved the management of the session when the applications are terminated or backgrounded, to reflect the newest changes in the hardware Rev2 of the YubiKey 5Ci. 

- Fixed a bug with the key state on the FIDO2 and U2F services being unnecessary updated to the same value, triggering unnecessary KVO notifications. 

- The YubiKit Demo application includes two reusable helper classes, `KeySessionObserver` and `FIDO2ServiceObserver` in `Examples/Observers`, which show an example on how to translate from a KVO observation pattern to a delegate pattern, when a delegate pattern is preferred for the target application.

---

## 2.0.0 B7

- This version adds compatibility with the hardware Rev2 of the YubiKey 5Ci. This includes support for CTAP2/FIDO2 requests against the key with some limitations (PIN authentication not supported yet by the library). Note that this new functionality is not supported by the hardware Rev1 devices. To determine the hardware revision, run the demo application (wireless debugging enabled) and insert the key. The application will show in the console logs the information about the accessory, including the hardware revision.

- Updated the Other demos to include an API demo on how to use the FIDO2 functionality provided by the library.

- Minor bug fixes and improved session handling when multiple applications try to access the key concurrently.

- For more details on how to use these new interfaces check the documentation from *Readme.md*.

---

## 2.0.0 B6

- Updated the PC/SC interface to receive pre-allocated buffers, similar to the original PC/SC API. This new implementation adds support for ask-for-size and optional buffers. Removed the `A` suffix from some of the methods and refer in the API header documentation to the PCSCLite documentation which is more concise and cross-platform.

- Added a new PC/SC function, similar to `pcsc_stringify_error` from PCSCLite, `YKFPCSCStringifyError`, which returns a human readable error description for a given, known, PC/SC error code.

- The PC/SC interface is exposing basic support for the PC/SC method `SCardGetStatusChange`, YubiKit version: `YKFSCardGetStatusChange`, which returns immediately the status of the card.

- The PC/SC interface tracks better contexts and cards and returns errors when a context or a card is invalid.

- Minor updates to the YubiKit Demo application and bug fixes.

---

## 2.0.0 B5

- The `YKFRawCommandService` provides the ability to execute sync commands against the key. 
The `YKFSession` provides the ability to check if the key is connected to the device regardless of the session state. New APIs for opening and closing synchronously the session have been added to ease the development when using the raw interface.

- The YubiKit Demo application has been updated to provide a demo for the raw interface when using the sync API from `YKFRawCommandService`.

- The YubiKit Demo application was improved for iPad. Now the application allows to test the OTP reading using the YubiKey for Lightning when the device does not support NFC reading. The application has an improved UI for the Lightning action sheet which can be easier reused.

---

## 2.0.0 B4

- The library provides the possibility to run raw commands against the YubiKey 5Ci. To allow this, a new service, `YKFRawCommandService` was introduced. This service allows to execute custom built APDU commands when the host application needs a very specific interaction with the key.

- Together with the `YKFRawCommandService` the library provides a new, PC/SC like decoupled interface to interact with the key. This interface is still in a prototype stage (POC).

- The YubiKit Demo application includes a new tab, Other, which is collection of miscellaneous small demos. Currently the list has only one demo, for the Raw Command interface.

- For more details on how to use these new interfaces check the documentation from *Readme.md*.

---

## 2.0.0 B3

- The `YKFSession` is exposing a new service for OATH credentials, `oathService`. The OATH service allows to interact with the OATH application from the key by using the [YOATH protocol](https://developers.yubico.com/OATH/YKOATH_Protocol.html). For a complete description of the new functionality check the *Readme.md* file and the header documentation for `YKFOATHService`.

- The YubiKit Demo application contains now a demo on how to read an OTP from the YubiKey 5Ci. 

- A QuickStart guide has beed added to the documentation.

---

## 2.0.0 B2

- The `YKFSession` has a new property, `keyDescription`, which provides a list of properties about the connected key, like firmware version, device name, etc. For the complete list of properties check `YKFDescription`.

- The library can connect to newer version of the firmware which is using the **com.yubico.ylp** protocol name instead of **U2F**. To add support for this protocol add **com.yubico.ylp** to the list of supported external accessories protocols. U2F protocol name is deprecated starting from this version. The library still works with the U2F protocol devices.

- The `YKFConnectionError` has been renamed to `YKFSessionError` to have a consistent naming with `YKFSession`. The library provides a few more detailed errors for the session operations. Check the error codes from `YKFSessionError` for more details.

---

## 2.0.0 B1

- This release is a major update which adds initial support for YubiKeys with lightning connector. 

- This version provides functionality for performing only U2F operations. Read the integration documentation to see how to add support for the YubiKeys with lightning connector.

---

## 1.1.1

- This is a minor update which adds support for a new default URI format when reading the OTP over NFC. This update is required to allow the applications to support future YubiKey firmware revisions. 

- The new supported format of the URL is: [https://my.yubico.com/yk/#[otp_value]]()

---

## 1.1.0

This version has a few improvements on the NFC APIs and to the demo application:

- The check for NFC capabilities does a pre-check for devices with NFC chip or newer devices before interrogating the OS for the NFC capabilities to avoid a very rare CoreNFC crash on devices which do not have a NFC reader.
- The OTP token interface was updated and the `payload` property was removed because it can be inferred from the other properties of the token and it's not essential in the context of YubiKit.
- The `uri` and `text` properties from the `YKFOTPToken` provide now the full parsed URI/Text from the device (including the prepended protocol in case or URI).
- The demo application has a few UI updates and fixes a few layout issues on small screen devices (iPhone 5/5c/5s/SE)
- The demo application can now run on iOS 10.

---

## 1.0.0

This version does a few changes to the library interface. The provided interface should  provide from now on a final API for capabilities check, NFC and QR code scanning:

- Renamed the `YKFDeviceCapabilities` as `YubiKitDeviceCapabilities`, as the capabilities type becomes a top level library interface object, on par with `YubiKitManager`, `YubiKitConfiguration` and `YubiKitExternalLocalization`.
- The capabilities change allows a direct check without retrieving them from the shared instance of the YubiKitManager as in RC2: `YubiKitDeviceCapabilities.supportsNFCScanning`  and `YubiKitDeviceCapabilities.supportsQRCodeScanning`. For a complete example read the documentation (README.md file) for RC3 and consult the code of the demo application.
- The `YubiKitManager` type provides from now several types of _sessions_, each one of them being responsible to only one type of communication. This change allows for future extensibility and consistency of the APIs without transforming `YubiKitManager` into a mixed responsibility type, responsible for various types of requests. RC3 provides two sessions: `nfcReaderSession` and `qrReaderSession`. The previous calls on the managers are now part of these sessions so `YubiKitManager.shared.<method_call>` becomes `YubiKitManager.shared.[nfcReaderSession/qrReaderSession].<method_call>`. For a complete example read the documentation (README.md file) for RC3 and consult the code of the demo application.
 
---

## 1.0.0 RC2

- Exposing the cancel user action from the NFC OS action sheet which is returned as an error by CoreNFC APIs: `NFCReaderError.readerSessionInvalidationErrorUserCanceled`

---

## 1.0.0 RC1

Initial release with support for: 

 - Reading OTPs (YubicoOTP and HOTP) from NFC enabled YubiKeys.
 - Raw QR code scanning.
