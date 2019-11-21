## FIDO2 Operations With the YubiKey 5Ci and NFC-Enabled YubiKeys 

The FIDO2 Authentication Standard is the most recent set of specifications from the FIDO Alliance. FIDO2 includes more specifications:

- The communication between the client (native application, browser, etc.) and the server is described by the [WebAuthn specifications](https://www.w3.org/TR/webauthn).
- The communication between the client and the authenticator (e.g. YubiKey) is described by the [CTAP2 protocol](https://fidoalliance.org/specs/fido-v2.0-id-20180227/fido-client-to-authenticator-protocol-v2.0-id-20180227.html) (Client To Authenticator Protocol version 2). YubiKit provides the functionality for talking CTAP2 with the YubiKey 5Ci.

The goal of this documentation is not to provide a full explanation of FIDO2 but to explain how to use the FIDO2 functionality with YubiKit and the YubiKey 5Ci. For a more detailed explanation of FIDO2 you are encouraged to access the resources from Yubico developer website.

The FIDO2 standard is very similar to FIDO U2F. FIDO2 is an evolution of the FIDO U2F, which allows for more flexibility and customization. Some of the most important differences are:

- The possibility to store the credential keys on the device (called *resident keys*). U2F allows only for derived keys.
- FIDO2 adds the possibility to ask for *user verification* (PIN, biometric, etc.) and for *user presence* (usually touch). U2F requires only user presence.
- In FIDO2, a service which wants to create a credential (a Relying Party) can specify RSA keys for the credential. In U2F only ECC keys can be generated.
- When creating a new credential on the key, an exclude list can be specified to avoid creating multiple credentials with the same key.

Like in FIDO U2F, the FIDO2 operations can be logically separated in 3 steps:

1. The application is requesting from the authentication server (WebAuthn server) some information which is required by the YubiKey to perform the operation (creating a credential or requesting an assertion).
2. The application is sending that information to the YubiKey and waits for a result.
3. The application sends the result to the authentication server to be validated.

Steps [1] and [3] are custom to each application. These usually involve some HTTPS calls to the server infrastructure used by the application to get and send data back. The second step is where the application is using YubiKit and the YubiKey.

YubiKit provides FIDO2 support through a single shared instance, `fido2Service` (of type `YKFKeyFIDO2Service`) which is a property of `YKFAccessorySession` or `YKFNFCSession`. The FIDO2 service behaves in a similar way with the other services from the key session. It will receive requests and dispatch them asynchronously to be executed by the key. The FIDO2 service is available only when the key is connected to the device and there is an opened session with the key. If the key session is closed or the key is disconnected the `fido2Service` property is nil. 

The `sessionState` property on the key session can be observed to check the state of the session and take appropriate actions to update the UI or to send requests to the key. Because the KVO code can be verbose, a complete example on how to observe this property is provided in the demo application and not here. When the host application prefers a delegate pattern to observe this property, the Demo application provides an example on how to isolate the KVO observation into a separate class and use a delegate to update about changes. The example can be found in the `Examples/Observers` project group.

To get a description of the authenticator, the `YKFKeyFIDO2Service` provides the `[executeGetInfoRequestWithCompletion:]` method which is a high level API for the CTAP2 `authenticatorGetInfo` command. This information can be requested as follows:

#### Swift

```swift
let accessorySession = YubiKitManager.shared.accessorySession
    
guard let fido2Service = accessorySession.fido2Service else {
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

#### Objective-C

```objective-c
#import <YubiKit/YubiKit.h>
...

YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.accessorySession.fido2Service;
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

Using the FIDO APIs over the NFC session is identical to using the APIs over the accessory (used for the YubiKey 5Ci as an MFi accessory) session. The application builds the requests in the same way and the application can choose to execute requests over the *accessory* or the *NFC* session:

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

A new FIDO2 credential can be created by calling `[executeMakeCredentialRequest:completion:]` on the FIDO2 service. The following code will create a new credential with a non-resident ECC key:
 
#### Swift

```swift
// Not a resident key and no PIN required.
let makeCredentialOptions = [YKFKeyFIDO2MakeCredentialRequestOptionRK: false, 
								  YKFKeyFIDO2MakeCredentialRequestOptionUV: false]	
let alg = YKFFIDO2PublicKeyAlgorithmES256
	
guard let fido2Service = YubiKitManager.shared.accessorySession.fido2Service else {           
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

#### Objective-C

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
    
YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.accessorySession.fido2Service;
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
	
In FIDO2, during the authentication phase, the Relying Party will ask from the user to approve and provide an assertion from the authenticator (in this case the YubiKey5Ci), after the authenticator was registered as a 2FA method. YubiKit provides the `[executeGetAssertionRequest:completion:]` method on the `YKFKeyFIDO2Service`, which allows to retrieve an assertion from the key:

#### Swift

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
	
guard let fido2Service = YubiKitManager.shared.accessorySession.fido2Service else {
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

#### Objective-C

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
	
YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.accessorySession.fido2Service;
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

The FIDO2 standard defines the ability to set a PIN on the authenticator. In this way an additional level of security can be enabled for certain operations with the key. By default the YubiKey has no PIN set on the FIDO2 application. The PIN can be any alphanumeric combination (between 4 and 255 UTF8 encoded characters). Once the PIN is set on the FIDO2 application, it can be only changed but not removed. The only way to remove the PIN is by resetting the FIDO2 application. Keep in mind that the Reset operation is destructive and all the keys will be removed as well.

The most common scenario, where PIN verification is required, happens when adding a new credential to the key. This operation requires more privileges so the YubiKey will ask for PIN verification, if any PIN was set on the FIDO2 application.

When the key requires PIN verification for an operation, YubiKit will return the error code `YKFKeyFIDO2ErrorCode.PIN_REQUIRED`. In this particular scenario the application can cache the request, perform the PIN verification and retry the request. This flow is implemented in the `FIDO2ViewController`. 

To verify the PIN, the FIDO2 Service provides the `[executeVerifyPinRequest:completion:]` method:

#### Swift

```swift
let accessorySession = YubiKitManager.shared.accessorySession
guard let fido2Service = accessorySession.fido2Service else {
    // The session with the accessory key is closed
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

#### Objective-C

```objective-c
YKFKeyFIDO2Service *fido2Service = YubiKitManager.shared.accessorySession.fido2Service;
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

YubiKit provides also the ability set and change the PIN. The requests are very similar to the PIN verification and a complete example is implemented in the YubiKit Demo application, `FIDO2DemoViewController`.

---

**Important Notes:**

1. After PIN verification, YubiKit will automatically append the required PIN auth data to the FIDO2 requests when necessary. YubiKit does not cache any PIN. Instead it's using a temporary shared token, which was agreed between the key and YubiKit as defined by the CTAP2 specifications. This token is valid as long the session is opened and it's not persistent.

2. After verifying the PIN and executing the necessary requests with the key, the application can clear the shared token cache by calling `[clearUserVerification]` on the FIDO2 Service. This will also happen when the key is unplugged, taken away from the device, or when the session is closed programmatically.

3. After changing the PIN, a new PIN verification is required. 

---

The YubiKit Demo application provides detailed demos on how to use the FIDO2 functionality of the library: 

- The `FIDO2 Demo` in the Other demos provides a self-contained demo for the requests discussed in this section and more details about the API. 

- The demo available in the FIDO2 tab of the application provides a complete example on how YubiKit can be used together with a WebAuthn server to register and authenticate. 
