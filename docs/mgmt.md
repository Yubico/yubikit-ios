## Using YubiKey Management Service 

This `YKFKeyMGMTService`  is using  `YKFKeyRawCommandService`  to communicate with YubiKey. How to implement such service yourself using  `YKFKeyRawCommandService`  read [here](../docs/raw.md)

The `YKFKeyMGMTService` provides 2 methods:
1) reading request that provides you `YKFMGMTInterfaceConfiguration` YubiKey within reading response. 
2) writing request that accepts the same  `YKFMGMTInterfaceConfiguration` with updated flags on properties that needs to be tweaked (enabled/disabled)

##### Objective-C

```objective-c
 #import <YubiKit/YubiKit.h>
  
 ...
 YKFKeyMGMTService *service = [[YKFKeyMGMTService alloc] init];
 [service readConfigurationWithCompletion:^(YKFKeyMGMTReadConfigurationResponse *selectionResponse, NSError *error) {
     if (error) {
         // Handle the error
         return;
     }
     YKFMGMTInterfaceConfiguration *configuration = selectionResponse.configuration;
     
     if([configuration isSupported:YKFMGMTApplicationTypeOTP overTransport:YKFMGMTTransportTypeNFC]) {
        //if OTP/YubiKey/Challenge-response application is supported on the app
     }
     
     if ([configuration isEnabled:YKFMGMTApplicationTypeOTP overTransport:YKFMGMTTransportTypeNFC]) {
         //if OTP/YubiKey/Challenge-response application is enabled on the app
     }
     
}];
```    
    
##### Swift

```swift
let service = YKFKeyMGMTService()
mgtmService.readConfiguration { [weak self] (response, error) in
    guard let self = self else {
        return
    }
    
    if let error = error {
        // Handle the error
        return
    }
    
    let configuration = response.configuration

    ...
    
    configuration.setEnabled(true, application: .OTP, overTransport: .USB)
    
    mgtmService.write(self.configuration, reboot: true) { [weak self] error in
        if let error = error {
            // Handle the error
            return
        }
        //successfully updated
    }
}
```    

If method is invoked when there is no connection with YubiKey than methods of this service will return an error. So it's delegated to user of APIs to make sure that YubiKey is plugged in or tapped over NFC reader when prompted. This can be reached by observing state properties of sessions that has been started by user: the `sessionState` property of `YKFAccessorySession` ( or `iso7816SessionState` property of `NFCSession`). If state is open it means that connection has been established.
The example of such observer can be found in the Examples/Observers project group of YubiKitDemo project.

