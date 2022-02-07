// Copyright 2018-2022 Yubico AB
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

#ifndef TLVRecord_h
#define TLVRecord_h


typedef UInt64 YKFTLVTag;

@interface YKFTLVRecord : NSObject

/// Tag value of the record.
@property (nonatomic, readonly) YKFTLVTag tag;

/// Value field of the record.
@property (nonatomic, readonly) NSData * _Nonnull value;

/// Data object containing whole encoded record, including tag, length and value.
@property (nonatomic, readonly) NSData * _Nonnull data;

/// Creates BERTLV record with specified tag and value.
/// @param tag Tag value for the new record.
/// @param value Value for the new record.
/// @return Newly created BERTLV record.
- (instancetype _Nonnull )initWithTag:(YKFTLVTag)tag value:(NSData *_Nonnull)value;

/// Creates BERTLVRecord with specified tag and array of children TKTLVRecord instances as subrecords.
/// @param tag Tag value for the new record.
/// @param records Array of BERTLVRecord instances serving as subrecords of this record.
/// @return Newly created BERTLV record.
- (instancetype _Nonnull )initWithTag:(YKFTLVTag)tag records:(NSArray<YKFTLVRecord *> *_Nonnull)records;

/// Parses TLV record from data block
/// @param data Data block containing serialized form of BERTLV record.
/// @return newly parsed record instance or nil if data do not represent valid record.
+ (nullable instancetype)recordFromData:(NSData *_Nullable)data;

/// Parses sequence of BERTLV records from data block.
/// The amount of records is determined by the length of input data block.
/// @param data Data block containing zero or more serialized forms of TLV record.
/// @return An array of BERTLV record instances parsed from input data block or nil if data do not form valid BERTLV record sequence.
+ (nullable NSArray<YKFTLVRecord *> *)sequenceOfRecordsFromData:(NSData *_Nullable)data;

- (instancetype _Nonnull )init NS_UNAVAILABLE;

@end

#endif /* YKFTLVRecord_h */
