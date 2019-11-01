#!/bin/sh

brew install imagemagic

mkdir Bin/LINUX/Resource && make data
cd ios 
pod update && open LK8000.xcworkspace
