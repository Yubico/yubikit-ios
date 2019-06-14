# Quick Start Guide

--

This guide provides a few steps to follow before starting with YubiKit and the YubiKey for Lightning:

1. YubiKit requires a physical key to test its features. Before running the demo app you need a NFC-Enabled YubiKey (Neo or YK 5 NFC) to test the NFC functionality and a YubiKey for Lightning to use the lightning demos from the application.

2. Before starting to look at the SDK make sure you have the .zip file containing all the necessary assets for using the library. The most important ones are:
	- The **YubiKit** folder containing the binary distribution of the library.
	- The **YubiKitDemo** folder containing the SDK Demo application.
	- The **Readme.md** which contains detailed information on how to use the library.

3. Have a quick look at the **Readme.md** file to familiarise with the features of the YubiKey for Lightning and YubiKit.

4. Open the YubiKitDemo Xcode project and run it on a real device (not simulator). YubiKit interacts with the phones NFC reader and with a YubiKey for Lightning so a real device is required to see the features of the SDK. 

5. The SDK Demo application provides demos for every major functionality of the key:
	- The **FIDO2 tab** is a demo for FIDO2/CTAP2. To test it you first need to be in possession of a YubiKey for Lightning. Press *Register* on the top and follow the steps to register a test account. After registering try to authenticate with the same credentials by selecting the *Authenticate* tab. In both cases the application will ask to insert the YubiKey Lightning in the device to perform the FIDO2 operations.
	- The **OTP tab** is a demo for scanning an OTP over NFC or reading an OTP from the YubiKey for Lightning. To read an OTP press the *Read* button. The application will ask how to read the OTP (over Lightning or NFC). When selecting *Over NFC* the application needs a YubiKey with NFC support (NEO or YK 5 NFC) to read an OTP from it. Scan the NFC-Enabled key when the NFC scan action sheet is presented. When selecting *Over Lightning* the demo application will read an OTP from the YubiKey for Lightning if the instructions from the application are followed.
	- The **QR tab** is a demo for the built-in QR code reader from YubiKit. Press scan to scan a QR code with YubiKit.
	- The **Other** tab is a collection of small or more concise demos (like the demos for the RawCommand service and the PC/SC like interface). This list contains also self-contained FIDO demos for both FIDO2 and FIDO U2F.

---

**Note:** All features listed above require the use of YubiKit together with a YubiKey. Please refer to the SDK Demo application source code and Readme.md documentation to see the specific requirements for each feature.

---