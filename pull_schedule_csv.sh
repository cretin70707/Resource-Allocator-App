#!/bin/bash
adb shell "find /storage/emulated/0/Download/ -name '*.csv' -exec basename {} \;" | while read file; do adb pull "/storage/emulated/0/Download/$file" ./; done
