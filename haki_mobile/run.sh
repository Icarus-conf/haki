#!/bin/bash

# Device IDs
ANDROID_ID="emulator-5554"
IOS_ID="0FFF7721-3040-4389-9BEE-DB9D6B83C235"

# Run on Android
flutter run -d $ANDROID_ID &

# Run on iOS
flutter run -d $IOS_ID &

# Wait for both processes
wait