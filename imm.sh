#!/bin/bash
mkdir -p imm
#https://github.com/wukongdaily/AutoBuildImmortalWrt/releases/download/Autobuild-x86-64/immortalwrt-24.10.0-x86-64-generic-squashfs-combined-efi.img.gz

REPO="1999cc/AutoBuildImmortalWrt"
TAG="Autobuild-x86-64"
OUTPUT_PATH="imm/immortalwrt.img.gz"

# 匹配模式：以 immortalwrt 开头，以 .img.gz 结尾
FILE_PATTERN='^immortalwrt.*\.img\.gz$'

# 先拉取 release 信息（只请求一次 API，避免重复调用）
RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPO}/releases/tags/${TAG}")

# 用正则匹配文件名
FILE_NAME=$(echo "$RELEASE_JSON" | jq -r ".assets[].name" | grep -E "$FILE_PATTERN" | head -n 1)

# 再根据文件名拿到下载地址
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r --arg name "$FILE_NAME" '.assets[] | select(.name == $name) | .browser_download_url')

# 此处可以替换op固件下载地址,但必须是 直链才可以,网盘那种地址是不行滴。举3个例子
# 原版OpenWrt
# DOWNLOAD_URL="https://downloads.openwrt.org/releases/24.10.0/targets/x86/64/openwrt-24.10.0-x86-64-generic-squashfs-combined-efi.img.gz"
# 原版immortalwrt
# DOWNLOAD_URL="https://downloads.immortalwrt.org/releases/24.10.0/targets/x86/64/immortalwrt-24.10.0-x86-64-generic-squashfs-combined-efi.img.gz"
# 原版KWRT
# DOWNLOAD_URL="https://dl.openwrt.ai/releases/24.10/targets/x86/64/kwrt-03.08.2025-x86-64-generic-squashfs-combined-efi.img.gz"

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "错误：未找到文件 $FILE_NAME"
  exit 1
fi

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"
curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

if [[ $? -eq 0 ]]; then
  echo "下载immortalwrt-24.10.1成功!"
  file imm/immortalwrt.img.gz
  echo "正在解压为:immortalwrt.img"
  gzip -d imm/immortalwrt.img.gz
  ls -lh imm/
  echo "准备合成 immortalwrt 安装器"
else
  echo "下载失败！"
  exit 1
fi

mkdir -p output
docker run --privileged --rm \
        -v $(pwd)/output:/output \
        -v $(pwd)/supportFiles:/supportFiles:ro \
        -v $(pwd)/imm/immortalwrt.img:/mnt/immortalwrt.img \
        debian:buster \
        /supportFiles/immortalwrt/build.sh
