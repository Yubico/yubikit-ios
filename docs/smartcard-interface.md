
## Using the SmartCardInterface

In some scenarios the application may require to interact with the YubiKey in a very specific way which is not covered by the existing key sessions. Such scenarios may include:

1. The application needs to interact with multiple key applications inside a very complex flow.
2. YubiKit may not provide a service to a not very commonly used key application.
3. The application has already integrations with other libraries/accessories and there is an existing architecture which implements a binary communication with them.
4. Some specific project or design requirements.

---

**Note:**
It is recommended to use high level APIs when possible because they already provide a good integration with the key (e.g. If the application wants to perform U2F requests it's better to use the provided U2F Service instead of re-implementing the logic inside the application over the SmartCardInterface).

---

The `YKFSmartCardInterface` provides a simple API for sending asynchronous requests to the key. In the following example the application executes a request for selecting the PIV application from the card:

##### Swift

```swift

guard let smartCardInterface = connection.smartCardInterface else { /* Connection has closed */ return }
    
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
    
// Asynchronous command execution. The executeCommand() can be called from any thread.
smartCardInterface.executeCommand(firstApdu) { response, error in
    guard error == nil else {
        // Handle the error
        return
    }
    assert(response != nil, "The response cannot be nil at this point.")
    // Use the response from the key
}
```    

##### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>

YKFSmartCardInterface *smartCardInterface = connection.smartCardInterface;
if (!smartCardInterface) {
    // Connection has closed.
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
    
// Asynchronous command execution. The [executeCommand:] can be called from any thread.
    
[smartCardInterface executeCommand:apdu completion:^(NSData *response, NSError *error) {
    if (error) {
        // Handle the error
        return;
    }
    // Use the response from the key
    NSAssert(response, @"The response cannot be nil at this point.");
}];
```
