#!/bin/bash

# Define the name for the output IPA file
IPA_NAME="Payload.ipa"

# 1. 读取并更新 pubspec.yaml 的版本号
PUBSPEC_FILE="pubspec.yaml"

# 获取当前版本号 (例如: 0.1.0+7)
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC_FILE" | sed 's/version: //')
if [[ -z "$CURRENT_VERSION" ]]; then
    echo "未找到 pubspec.yaml 中的版本号。退出..."
    exit 1
fi

# 提取版本号 (例如: 0.1.0) 和构建号 (例如: 7)
VERSION_NUMBER=$(echo "$CURRENT_VERSION" | cut -d "+" -f 1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d "+" -f 2)

# 将版本号拆分为 major, minor, 和 patch (例如: 0, 1, 0)
MAJOR=$(echo "$VERSION_NUMBER" | cut -d "." -f 1)
MINOR=$(echo "$VERSION_NUMBER" | cut -d "." -f 2)
PATCH=$(echo "$VERSION_NUMBER" | cut -d "." -f 3)

# 递增 patch 版本号 (例如: 从 0.1.0 到 0.1.1)
NEW_PATCH=$((PATCH + 1))
NEW_VERSION_NUMBER="${MAJOR}.${MINOR}.${NEW_PATCH}"

# 构建号保持不变
NEW_BUILD_NUMBER=$BUILD_NUMBER  # 保持构建号或根据需要重置为 1

# 合并新的版本号和构建号
NEW_VERSION="${NEW_VERSION_NUMBER}+${NEW_BUILD_NUMBER}"

# 更新 pubspec.yaml 文件中的版本号
echo "更新版本号从 $CURRENT_VERSION 到 $NEW_VERSION 在 $PUBSPEC_FILE 中"
sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"

# 2. 使用 Flutter 构建 iOS 应用
echo "正在以版本 $NEW_VERSION 构建 iOS 应用（release 模式）..."
flutter build ios --release --dart-define=ENVIRONMENT=production --dart-define=BASE_URL=https://ai-miniprogram.fancyzh.top --obfuscate --split-debug-info=./debug-info

# 检查构建是否成功
if [ $? -ne 0 ]; then
    echo "Flutter 构建失败。退出..."
    exit 1
fi

# 3. 定位到生成的 Runner.app
APP_PATH="build/ios/iphoneos/Runner.app"

if [ ! -d "$APP_PATH" ]; then
    echo "未找到 Runner.app 位于 $APP_PATH。退出..."
    exit 1
fi

# 4. 创建 Payload 文件夹并将 Runner.app 移动到其中
echo "创建 Payload 文件夹..."
mkdir -p Payload
cp -r "$APP_PATH" Payload/

# 5. 压缩为 .ipa 文件
echo "正在将 Payload 压缩为 $IPA_NAME..."
zip -r "$IPA_NAME" Payload

# 6. 清理临时文件夹
echo "正在清理临时文件..."
rm -rf Payload

# 7. 提示生成成功
echo "IPA 包已创建: $IPA_NAME"
echo "应用版本号已更新为 $NEW_VERSION"
