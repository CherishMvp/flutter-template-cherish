#!/bin/bash

# 清理flutter项目
flutter clean

# 删除ios目录下的Pods文件夹
rm -rf ios/Pods

# 删除ios目录下的Podfile
rm -rf ios/Podfile

# 删除ios目录下的Podfile.lock
rm -rf ios/Podfile.lock

# 更新flutter项目的依赖
flutter pub get

# 进入ios目录
cd ios

# 安装CocoaPods依赖
pod install
