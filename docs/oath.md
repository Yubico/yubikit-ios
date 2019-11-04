
## OATH Operations for the YubiKey 5Ci and NFC-Enabled YubiKeys

The [YKOATH protocol](https://developers.yubico.com/OATH/YKOATH_Protocol.html) is used to manage and use OATH credentials with a YubiKey. The YKOATH protocol is part of the CCID interface of the key. The CCID interface is enabled by default on the YubiKey 5Ci. 

YubiKit provides OATH support through a single shared instance, `oathService` (of type `YKFKeyOATHService`), a property of the `YKFAccessorySession` or `YKNFCSession`. The OATH service is very similar in behavior with the U2F service from the Accessory Session. It will receive requests and dispatch them asynchronously to be executed by the key. The OATH service is available only when the key is connected to the device (or nearby for NFC) and there is an opened session with the key. If the key session is closed or the key is disconnected the `oathService` property is `nil`. 

The `sessionState` property on the Accessory or NFC Session can be observed to check the state of the session and take appropriate actions to update the UI or to send requests to the key. 

The OATH Service provides a method for every command from the YOATH protocol to add, remove, list and calculate credentials. For the complete list of methods look at the `YKFKeyOATHService` code level documentation. 

YubiKit provides also a class for defining an OATH Credential, `YKFOATHCredential`, which has a convenience initializer which can receive a credential URL conforming to the [Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format) and parse the credential parameters from it.

Here are a few snippets on how to use the OATH functionality of the YubiKey through YubiKit:

#### Swift

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
    
guard let oathService = YubiKitManager.shared.accessorySession.oathService else {
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

#### Objective-C

```objective-c
// This is an URL conforming to Key URI Format specs.
NSString *oathUrlString = @"otpauth://totp/Yubico:example@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
NSURL *url = [NSURL URLWithString:oathUrlString];
NSAssert(url != nil, @"Invalid OATH URL");
    
// Create the credential from the URL using the convenience initializer.
YKFOATHCredential *credential = [[YKFOATHCredential alloc] initWithURL:url];
NSAssert(credential != nil, @"Could not create OATH credential.");
    
id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
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
	
In addition to these requests, the OATH Service provides an interface for setting/validating a password on the OATH application, calculate all credentials and resetting the OATH application to its default state.

---

**Tips:**
Authenticators often use QR codes to pass the URL for setting up the credentials. The built-in QR Code reader from YubiKit can be used to read the credential URL.

---