## Using the Raw Command Service and the PC/SC like interface 

In some scenarios the application may require to interact with the YubiKey in a very specific way which is not covered by the existing key services. Such scenarios may include:

1. The application needs to interact with multiple key applications inside a very complex flow.
2. YubiKit may not provide a service to a not very commonly used key application.
3. The application has already integrations with other libraries/accessories and there is an existing architecture which implements a binary communication with them.
4. Some specific project or design requirements.

---

**Note:**
It is recommended to use high level APIs when possible because they already provide a good integration with the key (e.g. If the application wants to perform U2F requests it's better to use the provided U2F Service instead of re-implementing the logic inside the application over the raw interface).

---

For such scenarios YubiKit allows to send raw commands to the key over two channels: using the `YKFRawCommandService` or over a `PC/SC like` interface. 

The `YKFRawCommandService` provides a simple API for sending synchronous and asynchronous requests to the key. In the following example the application executes a request for selecting the PIV application from the card:

##### Objective-C

```objective-c
 #import <YubiKit/YubiKit.h>
  
 ...

id<YKFRawCommandSessionProtocol> rawCommandService =  YubiKitManager.shared.accessorySession.rawCommandService;
if (!rawCommandService) {
    // The key is not connected, nearby, or the key session is not started if the rawCommandService is nil.
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
guard let rawCommandService = YubiKitManager.shared.accessorySession.rawCommandService else {
    // The key is not connected, nearby, or the key session is not started if the rawCommandService is nil
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
Using the raw command service APIs over the NFC session is identical to using the APIs over the accessory (used for the YubiKey 5Ci as an MFi accessory) session. The application builds the requests in the same way and the application can choose to execute requests over the *accessory* or the *NFC* session:

```swift
let rawCommandService = YubiKitManager.shared.nfcSession.rawCommandService
```

```objective-c
id<YKFRawCommandSessionProtocol> rawCommandService =  YubiKitManager.shared.nfcSession.rawCommandService;
```


The YubiKit Demo application has a more detailed demo on how to use the Raw Command service in `RawCommandServiceDemoViewController`.
    
YubiKit provides also a `PC/SC like` interface for sending raw commands to the key. This interface is exposed in `YKFPCSC.h`. For a complete list of methods consult the header file and the code level documentation.

Currently this service is supported only for `accessorySession`.

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
