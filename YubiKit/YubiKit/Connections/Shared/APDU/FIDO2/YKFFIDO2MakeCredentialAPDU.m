// Copyright 2018-2019 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "YKFFIDO2MakeCredentialAPDU.h"
#import "YKFCBOREncoder.h"
#import "YKFAssert.h"
#import "YKFFIDO2Type.h"
#import "YKFFIDO2Type+Private.h"
#import "YKFNSDataAdditions.h"

typedef NS_ENUM(NSUInteger, YKFFIDO2MakeCredentialAPDUKey) {
    YKFFIDO2MakeCredentialAPDUKeyClientDataHash     = 0x01,
    YKFFIDO2MakeCredentialAPDUKeyRp                 = 0x02,
    YKFFIDO2MakeCredentialAPDUKeyUser               = 0x03,
    YKFFIDO2MakeCredentialAPDUKeyPubKeyCredParams   = 0x04,
    YKFFIDO2MakeCredentialAPDUKeyExcludeList        = 0x05,
    YKFFIDO2MakeCredentialAPDUKeyExtensions         = 0x06,
    YKFFIDO2MakeCredentialAPDUKeyOptions            = 0x07,
    YKFFIDO2MakeCredentialAPDUKeyPinAuth            = 0x08,
    YKFFIDO2MakeCredentialAPDUKeyPinProtocol        = 0x09,
};

@implementation YKFFIDO2MakeCredentialAPDU

- (nullable instancetype)initWithClientDataHash:(NSData *)clientDataHash
                                             rp:(YKFFIDO2PublicKeyCredentialRpEntity *)rp
                                           user:(YKFFIDO2PublicKeyCredentialUserEntity *)user
                               pubKeyCredParams:(NSArray *)pubKeyCredParams
                                     excludeList:(NSArray * _Nullable)excludeList
                                        pinAuth:(NSData * _Nullable)pinAuth
                                    pinProtocol:(NSUInteger)pinProtocol
                                        options:(NSDictionary  * _Nullable)options
                                     extensions:(NSDictionary * _Nullable)extensions {
    
    YKFAssertAbortInit(clientDataHash);
    YKFAssertAbortInit(rp);
    YKFAssertAbortInit(user);
    YKFAssertAbortInit(pubKeyCredParams);
    
    
    /*
     dictionary PublicKeyCredentialCreationOptionsJSON {
         required PublicKeyCredentialRpEntity                    rp;
         required PublicKeyCredentialUserEntityJSON              user;
         required Base64URLString                                challenge;
         required sequence<PublicKeyCredentialParameters>        pubKeyCredParams;
         unsigned long                                           timeout;
         sequence<PublicKeyCredentialDescriptorJSON>             excludeCredentials = [];
         AuthenticatorSelectionCriteria                          authenticatorSelection; // This is hardcoded for now
         sequence<DOMString>                                     hints = [];
         DOMString                                               attestation = "none";
         sequence<DOMString>                                     attestationFormats = [];
         AuthenticationExtensionsClientInputsJSON                extensions;
     };

     */
    
    NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
    
    // Client Data Hash
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyClientDataHash)] = YKFCBORByteString(clientDataHash);
    
    // RP
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyRp)] = [rp cborTypeObject];
    
    // User
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyUser)] = [user cborTypeObject];
    
    // PubKeyCredParams
    NSMutableArray *mutablePubKeyCredParams = [[NSMutableArray alloc] initWithCapacity:pubKeyCredParams.count];
    for (YKFFIDO2PublicKeyCredentialType *credentialType in pubKeyCredParams) {
        [mutablePubKeyCredParams addObject:[credentialType cborTypeObject]];
    }
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyPubKeyCredParams)] = YKFCBORArray(mutablePubKeyCredParams);
    
    // ExcludeList
    if (excludeList) {
        NSMutableArray *mutableExcludeList = [[NSMutableArray alloc] initWithCapacity:excludeList.count];
        for (YKFFIDO2PublicKeyCredentialDescriptor *descriptor in excludeList) {
            [mutableExcludeList addObject:[descriptor cborTypeObject]];
        }
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyExcludeList)] = YKFCBORArray(mutableExcludeList);
    }
    
    // Options
    if (options) {
        NSMutableDictionary *mutableOptions = [[NSMutableDictionary alloc] initWithCapacity:options.count];
        NSArray *optionsKeys = options.allKeys;
        for (NSString *optionKey in optionsKeys) {
            NSNumber *value = options[optionKey];
            mutableOptions[YKFCBORTextString(optionKey)] = YKFCBORBool(value.boolValue);
        }
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyOptions)] = YKFCBORMap(mutableOptions);
    }
    
    // Extensions
    NSMutableDictionary *extensionsDict = [NSMutableDictionary new];
    // Sign
    if (extensions && extensions[@"sign"] && extensions[@"sign"][@"generateKey"]) {
        NSDictionary *generateKeyDict = (NSDictionary *) extensions[@"sign"][@"generateKey"];
        NSMutableDictionary *signExtensionDict = [NSMutableDictionary new];
        // Flags hard coded for now. More information here:
        // https://github.com/Yubico/python-fido2/blob/8722a8925509d3320f8cb6d8a22c76e2af08fb20/fido2/ctap2/extensions.py#L493
        int flags = 0b101;
        
        NSMutableArray *algorithms = [NSMutableArray array];
        [(NSArray *)generateKeyDict[@"algorithms"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSInteger intValue = [(NSNumber *)obj integerValue];
            [algorithms addObject:YKFCBORInteger(intValue)];
        }];
        signExtensionDict[YKFCBORInteger(3)] = YKFCBORArray(algorithms);
        signExtensionDict[YKFCBORInteger(4)] = YKFCBORInteger(flags);
        
        if (generateKeyDict[@"phData"]) {
            NSString * phData = generateKeyDict[@"phData"];
            NSData *phDataBase64Encoded = [[NSData alloc] initWithBase64EncodedString:phData options:0];
            signExtensionDict[YKFCBORInteger(0)] = YKFCBORByteString(phDataBase64Encoded);
        }
        extensionsDict[YKFCBORTextString(@"sign")] = YKFCBORMap(signExtensionDict);
    }
    
    // Extensions large blob
    if (extensions && extensions[@"largeBlobKey"] && [extensions[@"largeBlobKey"][@"support"] isEqual: @"required"]) {
        extensionsDict[YKFCBORTextString(@"largeBlobKey")] = YKFCBORBool(true);
    }

    // Extensions hmac-secret
    if (extensions && extensions[@"hmac-secret"]) {
        extensionsDict[YKFCBORTextString(@"hmac-secret")] = YKFCBORBool(true);
    }
    
    if (extensionsDict.count > 0) {
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyExtensions)] = YKFCBORMap(extensionsDict);
    }

    
    // Pin Auth
    if (pinAuth) {
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyPinAuth)] = YKFCBORByteString(pinAuth);
    }
    
    // Pin Protocol
    if (pinProtocol) {
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyPinProtocol)] = YKFCBORInteger(pinProtocol);
    }

    NSData *cborData = [YKFCBOREncoder encodeMap:YKFCBORMap(requestDictionary)];
    YKFAssertAbortInit(cborData);
    
    return [super initWithCommand:YKFFIDO2CommandMakeCredential data:cborData];
    
}

/*
- (instancetype)initWithRequest:(YKFFIDO2MakeCredentialRequest *)request {
    YKFAssertAbortInit(request)
    YKFAssertAbortInit(request.clientDataHash)
    YKFAssertAbortInit(request.rp)
    YKFAssertAbortInit(request.user)
    YKFAssertAbortInit(request.pubKeyCredParams)
    
    NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
    
    // Client Data Hash
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyClientDataHash)] = YKFCBORByteString(request.clientDataHash);
    
    // RP
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyRp)] = [request.rp cborTypeObject];
    
    // User
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyUser)] = [request.user cborTypeObject];
    
    // PubKeyCredParams
    NSMutableArray *pubKeyCredParams = [[NSMutableArray alloc] initWithCapacity:request.pubKeyCredParams.count];
    for (YKFFIDO2PublicKeyCredentialType *credentialType in request.pubKeyCredParams) {
        [pubKeyCredParams addObject:[credentialType cborTypeObject]];
    }
    requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyPubKeyCredParams)] = YKFCBORArray(pubKeyCredParams);
    
    // ExcludeList
    if (request.excludeList) {
        NSMutableArray *excludeList = [[NSMutableArray alloc] initWithCapacity:request.excludeList.count];
        for (YKFFIDO2PublicKeyCredentialDescriptor *descriptor in request.excludeList) {
            [excludeList addObject:[descriptor cborTypeObject]];
        }
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyExcludeList)] = YKFCBORArray(excludeList);
    }
    
    // Options
    if (request.options) {
        NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithCapacity:request.options.count];
        NSArray *optionsKeys = request.options.allKeys;
        for (NSString *optionKey in optionsKeys) {
            NSNumber *value = request.options[optionKey];
            options[YKFCBORTextString(optionKey)] = YKFCBORBool(value.boolValue);
        }
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyOptions)] = YKFCBORMap(options);
    }
    
    // Pin Auth
    if (request.pinAuth) {
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyPinAuth)] = YKFCBORByteString(request.pinAuth);
    }
    
    // Pin Protocol
    if (request.pinProtocol) {
        requestDictionary[YKFCBORInteger(YKFFIDO2MakeCredentialAPDUKeyPinProtocol)] = YKFCBORInteger(request.pinProtocol);
    }

    NSData *cborData = [YKFCBOREncoder encodeMap:YKFCBORMap(requestDictionary)];
    YKFAssertAbortInit(cborData);
    
    return [super initWithCommand:YKFFIDO2CommandMakeCredential data:cborData];
}*/

@end
