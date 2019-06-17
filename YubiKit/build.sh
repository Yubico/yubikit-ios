#!/bin/sh

FRAMEWORK=YubiKit
LIBNAME=libYubiKit.a

DEBUG_OUTPUT=debug
DEBUG_BUILD=build/$DEBUG_OUTPUT

RELEASE_OUTPUT=release
RELEASE_BUILD=build/$RELEASE_OUTPUT

DEBUG_UNIVERSAL_OUTPUT=debug_universal
DEBUG_UNIVERSAL_BUILD=build/$DEBUG_UNIVERSAL_OUTPUT

RELEASE_UNIVERSAL_OUTPUT=release_universal
RELEASE_UNIVERSAL_BUILD=build/$RELEASE_UNIVERSAL_OUTPUT

LIBRARY_RELEASES=releases

# Remove old build

rm -Rf $DEBUG_BUILD
rm -Rf $RELEASE_BUILD
rm -Rf $DEBUG_UNIVERSAL_BUILD

# Build

xcodebuild build \
    ARCHS="armv7 armv7s arm64" \
    -project $FRAMEWORK.xcodeproj \
    -target $FRAMEWORK \
    -sdk iphoneos \
    ONLY_ACTIVE_ARCH=NO \
    -configuration Debug \
    -destination "generic/platform=iOS" \
    SYMROOT=$DEBUG_BUILD

xcodebuild build \
    ARCHS="i386 x86_64" \
    -project $FRAMEWORK.xcodeproj \
    -target $FRAMEWORK \
    -sdk iphonesimulator \
    ONLY_ACTIVE_ARCH=NO \
    -configuration Debug \
    SYMROOT=$DEBUG_BUILD

xcodebuild archive \
    ARCHS="armv7 armv7s arm64" \
    -project $FRAMEWORK.xcodeproj \
    -scheme $FRAMEWORK \
    -sdk iphoneos \
    ONLY_ACTIVE_ARCH=NO \
    -destination "generic/platform=iOS" \
    SYMROOT=$RELEASE_BUILD

xcodebuild build \
    ARCHS="i386 x86_64" \
    -project $FRAMEWORK.xcodeproj \
    -target $FRAMEWORK \
    -sdk iphonesimulator \
    ONLY_ACTIVE_ARCH=NO \
    -configuration Release \
    SYMROOT=$RELEASE_BUILD

cp -RL $DEBUG_BUILD/Debug-iphoneos $DEBUG_UNIVERSAL_BUILD
cp -RL $RELEASE_BUILD/Release-iphoneos $RELEASE_UNIVERSAL_BUILD

lipo -create \
    $DEBUG_BUILD/Debug-iphoneos/$LIBNAME \
    $DEBUG_BUILD/Debug-iphonesimulator/$LIBNAME \
    -output $DEBUG_UNIVERSAL_BUILD/$LIBNAME

lipo -create \
    $RELEASE_BUILD/Release-iphoneos/$LIBNAME \
    $RELEASE_BUILD/Release-iphonesimulator/$LIBNAME \
    -output $RELEASE_UNIVERSAL_BUILD/$LIBNAME

# Cleanup

rm -Rf $DEBUG_BUILD

mv $RELEASE_BUILD/Release-iphoneos/* $RELEASE_BUILD
rm -Rf $RELEASE_BUILD/Release-iphoneos

# Package

rm -Rf $LIBRARY_RELEASES/$FRAMEWORK/$FRAMEWORK
mkdir -p $LIBRARY_RELEASES/$FRAMEWORK/$FRAMEWORK

cp -RL $DEBUG_UNIVERSAL_BUILD/include $LIBRARY_RELEASES/$FRAMEWORK/$FRAMEWORK
cp -RL $RELEASE_BUILD $LIBRARY_RELEASES/$FRAMEWORK/$FRAMEWORK
cp -RL $DEBUG_UNIVERSAL_BUILD $LIBRARY_RELEASES/$FRAMEWORK/$FRAMEWORK

rm -Rf $LIBRARY_RELEASES/$FRAMEWORK/$FRAMEWORK/$DEBUG_UNIVERSAL_OUTPUT/include
rm -Rf $LIBRARY_RELEASES/$FRAMEWORK/$FRAMEWORK/$RELEASE_OUTPUT/include

cp -RL ../YubiKitDemo $LIBRARY_RELEASES/$FRAMEWORK

# Copy license

cp -RL ../LICENSE $LIBRARY_RELEASES/$FRAMEWORK

# Copy documentation

cp -RL ../README.md $LIBRARY_RELEASES/$FRAMEWORK
cp -RL ../Guidelines.md $LIBRARY_RELEASES/$FRAMEWORK
cp -RL ../Changelog.md $LIBRARY_RELEASES/$FRAMEWORK
cp -RL ../QuickStart.md $LIBRARY_RELEASES/$FRAMEWORK
cp -RL ../docassets $LIBRARY_RELEASES/$FRAMEWORK
