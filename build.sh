#!/usr/bin/env bash
set -euo pipefail

# Ensure we use full Xcode (not just Command Line Tools) for iOS SDKs
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

LIB_NAME="fraccalc_core"
CRATE_DIR="fraccalc-core"
TARGET_DIR="${CRATE_DIR}/target"
BINDINGS_DIR="./bindings"
XCFRAMEWORK_DIR="./FracCalc/Frameworks/FracCalcCore.xcframework"

echo "==> Building for iOS device..."
cargo build --release --target aarch64-apple-ios --manifest-path "$CRATE_DIR/Cargo.toml"

echo "==> Building for iOS Simulator (ARM64)..."
cargo build --release --target aarch64-apple-ios-sim --manifest-path "$CRATE_DIR/Cargo.toml"

echo "==> Building for iOS Simulator (x86_64)..."
cargo build --release --target x86_64-apple-ios --manifest-path "$CRATE_DIR/Cargo.toml"

echo "==> Merging simulator slices..."
mkdir -p "${TARGET_DIR}/ios-sim-fat/release"
lipo -create \
    "${TARGET_DIR}/aarch64-apple-ios-sim/release/lib${LIB_NAME}.a" \
    "${TARGET_DIR}/x86_64-apple-ios/release/lib${LIB_NAME}.a" \
    -output "${TARGET_DIR}/ios-sim-fat/release/lib${LIB_NAME}.a"

echo "==> Generating Swift bindings..."
cargo build --manifest-path "$CRATE_DIR/Cargo.toml"
mkdir -p "$BINDINGS_DIR"
(cd "$CRATE_DIR" && cargo run --bin uniffi-bindgen generate \
    --library "target/debug/lib${LIB_NAME}.dylib" \
    --language swift \
    --out-dir "../$BINDINGS_DIR")

mv "${BINDINGS_DIR}/${LIB_NAME}FFI.modulemap" "${BINDINGS_DIR}/module.modulemap"

echo "==> Creating XCFramework..."
rm -rf "$XCFRAMEWORK_DIR"
mkdir -p "$(dirname "$XCFRAMEWORK_DIR")"
xcodebuild -create-xcframework \
    -library "${TARGET_DIR}/aarch64-apple-ios/release/lib${LIB_NAME}.a" \
        -headers "$BINDINGS_DIR" \
    -library "${TARGET_DIR}/ios-sim-fat/release/lib${LIB_NAME}.a" \
        -headers "$BINDINGS_DIR" \
    -output "$XCFRAMEWORK_DIR"

echo "Done."
echo "XCFramework: $XCFRAMEWORK_DIR"
echo "Swift binding: $BINDINGS_DIR/${LIB_NAME}.swift"
echo ""
echo "Add the .xcframework and .swift file to your Xcode project."
