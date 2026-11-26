#!/bin/bash
set -e
APP=build/RbxMulti.app
rm -rf build
SPARKLE_VERSION=2.10.0
SPARKLE_SHA256=17e28312b8e18ab7cdbbe09a6fb28cc55a5479ec6c371dbc07cdecd2a14fd959
SPARKLE_ARCHIVE=build/Sparkle-for-Swift-Package-Manager.zip
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks" build/icon.iconset
curl -fsSL "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-for-Swift-Package-Manager.zip" -o "$SPARKLE_ARCHIVE"
echo "$SPARKLE_SHA256  $SPARKLE_ARCHIVE" | shasum -a 256 -c -
unzip -q "$SPARKLE_ARCHIVE" -d build/sparkle
SPARKLE_FRAMEWORKS=build/sparkle/Sparkle.xcframework/macos-arm64_x86_64
for arch in arm64 x86_64; do
  swiftc -parse-as-library -O -target $arch-apple-macos13.0 \
    -F "$SPARKLE_FRAMEWORKS" -framework Sparkle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    Sources/*.swift -o build/RbxMulti-$arch
done
lipo -create build/RbxMulti-arm64 build/RbxMulti-x86_64 -output $APP/Contents/MacOS/RbxMulti
ditto "$SPARKLE_FRAMEWORKS/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
for s in 16 32 128 256 512; do
  sips -z $s $s Resources/icon_1024.png --out build/icon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) Resources/icon_1024.png --out build/icon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/icon.iconset -o $APP/Contents/Resources/AppIcon.icns
cp Info.plist $APP/Contents/Info.plist
cp LICENSE $APP/Contents/Resources/LICENSE.txt
cp build/sparkle/LICENSE $APP/Contents/Resources/Sparkle-LICENSE.txt
codesign --force --deep --sign - $APP
(cd build && ditto -c -k --keepParent RbxMulti.app RbxMulti.zip)
echo "Built build/RbxMulti.zip"
