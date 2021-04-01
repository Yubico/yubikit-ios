
## Reading OTPs from the YubiKey 5Ci and NFC-Enable YubiKeys

Unlike the other functionalities of a YubiKey, the OTP generation does not require an explicit call to YubiKit to fetch the OTP. The OTP generation works in a similar way with the generation of OTPs with an USB key. The YubiKey 5Ci acts as an external keyboard when sending the OTP to the OS and an NFC-Enabled YubiKey acts as NDEF tag read from the OS.

The OTP generation mechanism follows these steps when outputting the OTP into a preexisting text field which is the first responder, like a focused text field inside a web page:

1. The user plugs the key into the the device.
2. The user is touching the key.
3. The key will start emulating an external keyboard which will cause the virtual keyboard (if present) to be temporary dismissed.
4. The OTP is sent to the OS.
5. After the OTP transmission the key stops emulating the keyboard so the virtual keyboard will be again enabled.

Most of the time the OTP value is not important for the user so displaying it does not bring a significant value. In such a case the iOS frameworks provide several ways of intercepting the keyboard input without displaying a text field or the virtual keyboard. This allows to improve the UX by reading the OTP from the key with less steps while showing an explanatory UI to the user. The techniques to achieve this are application specific and mostly depend on the preferences of the developers.

One way of intercepting the keyboard input is to use `UIKeyCommand`. Key commands are usually used to intercept key combinations from the external keyboard and they can be attached to any `UIResponder`. The most common UIResponders are `UIView` and `UIViewController`. These fundamental classes of UIKit have the ability to `becomeFirstResponder` and they provide a property called `keyCommands` which can return a list of commands which will be triggered when the user is pressing a certain key combination on the external keyboard. An `UIKeyCommand` doesn't have to be a key combination. A certain character can be detected if the key command is created without modifiers. An example of such responder, `OTPUIResponder`, is implemented in the YubiKit Demo application. In the OTP demo the application will intercept the keyboard input using the `OTPUIResponder` to read the OTP from the YubiKey.

Sometimes the UX may involve some guiding steps for the user to plugin or to touch the key. In such a scenario YubiKit can be used to determine if the key is plugged in by implementing the `YKFManagerDelegate` protocol.

## Reading OTPs from NFC-Enabled YubiKeys

To request a NFC scan for an OTP token call `requestOTPToken:` on the `otpSession` instance from `YubiKitManager`:

##### Swift

```swift
YubiKitManager.shared.otpSession.requestOTPToken { token, error in
    guard let token = token else { /* Handle error */ return }
        // Use the token value
    }	
}
```

##### Objective-C		

```objective-c
#import <YubiKit/YubiKit.h>
...
[YubiKitManager.shared.otpSession requestOTPToken:^(id<YKFOTPTokenProtocol> token, NSError *error) {
    if token == nil { /* Handle error */ return; }
    // Use the token value
}];
```	

The `YKFOTPToken` contains the details of the scanned OTP token. The detailed documentation of all the properties is available in the header files provided with the library.

---

Before calling the APIs for NFC, it is recommended to check for the capabilities of the OS/Device. If the device or the OS does not support a capability **the library will fire an assertion** in debug builds when calling a method without having the required capability. YubiKit provides a handy utility class to check for these capabilities: `YubiKitDeviceCapabilities`:

##### Swift	

```swift
if YubiKitDeviceCapabilities.supportsNFCScanning {
    // Provide additional setup when NFC is available            
} else {
    // Handle the missing NFC support 
}
```

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...
// NFC scanning is available
if (YubiKitDeviceCapabilities.supportsNFCScanning) {
    // Provide additional setup when NFC is available
} else {
    // Handle the missing NFC support
}
```
---

In some conditions the NDEF payload format from a YubiKey can be modified and may have a custom way of appending metadata (as Text or URI) to the OTP token. In such a scenario, when the payload has a complex or non-standard format, the library allows the host application to provide a custom parser for the payload. 

The YubiKey can append two types of metadata to the OTP token: **Text** or **URI** (default one). To provide custom parsers the host application can use `YKFOTPURIParserProtocol` for a custom URI Parser and `YKFOTPTextParserProtocol` for a custom text parser. The code level documentation provides additional details on what the parsers should implement.

Here is an example of how to set a custom URI parser:

##### Swift

```swift
class CustomURIParser: YKFOTPURIParserProtocol {    
    // Custom parser implementation
}
...
YubiKitConfiguration.customOTPURIParser = CustomURIParser()
```

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

### Additional resources
Read more about Yubico OTP on the [Yubico developer site](https://developers.yubico.com/OTP//).
