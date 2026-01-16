#!/usr/bin/env swift

import CoreAudio
import Foundation

var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultInputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)

var deviceID: AudioDeviceID = 0
var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

let status = AudioObjectGetPropertyData(
    AudioObjectID(kAudioObjectSystemObject),
    &propertyAddress,
    0,
    nil,
    &dataSize,
    &deviceID
)

if status == noErr {
    // Get device name
    var namePropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceNameCFString,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var nameSize = UInt32(MemoryLayout<CFString>.size)
    var deviceName: Unmanaged<CFString>?
    
    let nameStatus = AudioObjectGetPropertyData(
        deviceID,
        &namePropertyAddress,
        0,
        nil,
        &nameSize,
        &deviceName
    )
    
    if nameStatus == noErr, let name = deviceName?.takeUnretainedValue() as String? {
        print("🎧 System default input device: \(name) (ID: \(deviceID))")
    } else {
        print("⚠️ Could not get device name")
    }
} else {
    print("❌ Could not get default input device")
}
