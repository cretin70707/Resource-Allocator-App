#!/bin/bash
adb shell "find /storage/emulated/0/Download/ -name '*.pdf' -exec basename {} \;" | while read file; do adb pull "/storage/emulated/0/Download/$file" ./; done
