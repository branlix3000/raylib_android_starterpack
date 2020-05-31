#!/bin/sh

echo "Step 0 - Preparing environment"
export ROOT=$(pwd)
mkdir android_home
export ANDROID_HOME=$ROOT/android_home
export ANDROID_API_VERSION=29

echo "Step 1 - Java SDK"

echo "This script assume that you have the latest Java SDK installed."

echo "Step 2 - Android SDK"

echo "Downloading the Android SDK."
if test ! -f commandlinetools-linux-6514223_latest.zip
then
  wget 'https://dl.google.com/android/repository/commandlinetools-linux-6514223_latest.zip'
else
  echo "The Android SDK has already been downloaded."
fi

echo "Verifying the Android SDK."
sha256sum -c commandlinetools-linux-6514223_latest.sha256
STATUS=$?
if test $STATUS -ne 0
then
  echo "ERROR: Android SDK file is not valid. Please delete the file and restart the script."
  exit 1
else
  echo "The Android SDK has correctly been downloaded."
fi

echo "Extracting files."
cd $ANDROID_HOME
mkdir cmdline-tools
cd cmdline-tools
unzip $ROOT/commandlinetools-linux-6514223_latest.zip

echo "Installing the Android SDK"
cd $ANDROID_HOME/cmdline-tools/tools/bin
export PATH=$PATH:$(pwd)
./sdkmanager --update
yes | ./sdkmanager --install "build-tools;29.0.3"
./sdkmanager --install platform-tools
./sdkmanager --install "platforms;android-$ANDROID_API_VERSION"
cd $ROOT

echo "Step 3 - Android NDK"

echo "Downloading the Android NDK."
if test ! -f android-ndk-r21c-linux-x86_64.zip
then
  wget 'https://dl.google.com/android/repository/android-ndk-r21c-linux-x86_64.zip'
else
  echo "The Android NDK has already been downloaded."
fi

echo "Verifying the Android NDK."
sha1sum -c android-ndk-r21c-linux-x86_64.sha1
STATUS=$?
if test $STATUS -ne 0
then
  echo "ERROR: Android NDK file is not valid. Please delete the file and restart the script."
  exit 1
else
  echo "The Android NDK has correctly been downloaded."
fi

echo "Install the Android NDK"
unzip android-ndk-r21c-linux-x86_64.zip
cp -ar android-ndk-r21c/* $ANDROID_HOME
rm -rf android-ndk-r21c

echo "Step 4 - Raylib"

echo "Setting up environment variables."
export ANDROID_NDK=$ANDROID_HOME
#export CXX=$ANDROID_TOOLCHAIN/bin/armv7a-linux-androideabi$ANDROID_API_VERSION-clang++

echo "Cloning the git repository."
git clone https://github.com/raysan5/raylib.git raylib

echo "DELETEME"
rm $ROOT/raylib/src/Makefile
cp /tmp/raylib/src/Makefile $ROOT/raylib/src/Makefile

echo "Compiling Raylib."
cd $ROOT/raylib/src
make PLATFORM=PLATFORM_ANDROID ANDROID_NDK=$ANDROID_HOME
cd $ROOT

echo "Checking libraylib.a."
if test ! -f $ROOT/raylib/src/libraylib.a
then
  echo "ERROR: libraylib.a hasn't been found."
  exit 1
fi

echo "Step 5 - Build"
cd $ROOT/project

echo "Preparing environment variables."
export ANDROID_TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64
export RAYLIB_GIT=$ROOT/raylib
export CC=$ANDROID_TOOLCHAIN/bin/armv7a-linux-androideabi$ANDROID_API_VERSION-clang

echo "Preparing libraylib.a."
mkdir -p lib/armeabi-v7a
cp $ROOT/raylib/src/libraylib.a lib/armeabi-v7a/
keytool -genkeypair -validity 1000 -dname "CN=seth,O=Android,C=ES" -keystore project.keystore -storepass 'whatever' -keypass 'whatever' -alias projectKey -keyalg RSA

echo "Preparing sample project."
cp $RAYLIB_GIT/templates/simple_game/simple_game.c project.c

echo "Build script - Part 1"
$CC -c $ANDROID_HOME/sources/android/native_app_glue/android_native_app_glue.c -o obj/native_app_glue.o -std=c99 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC -Wall -Wa,--noexecstack -Wformat -Werror=format-security -no-canonical-prefixes -DANDROID -DPLATFORM_ANDROID -D__ANDROID_API__=$ANDROID_API_VERSION

echo "Build script - Part 2"
$ANDROID_TOOLCHAIN/bin/arm-linux-androideabi-ar rcs obj/libnative_app_glue.a obj/native_app_glue.o

echo "Build script - Part 3"
$CC -c project.c -o obj/project.o -I. -I$RAYLIB_GIT/src -I$ANDROID_HOME/sources/android/native_app_glue -std=c99 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC -Wall -Wa,--noexecstack -Wformat -Werror=format-security -no-canonical-prefixes -DANDROID -DPLATFORM_ANDROID -D__ANDROID_API__=$ANDROID_API_VERSION --sysroot=$ANDROID_TOOCHAIN/sysroot

echo "Build script - Part 4"
$CC -o lib/armeabi-v7a/libproject.so obj/project.o -shared -I. -I$RAYLIB_GIT/src -I$ANDROID_HOME/sources/android/native_app_glue -Wl,-soname,libproject.so -Wl,--exclude-libs,libatomic.a -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings -u ANativeActivity_onCreate -L. -Lobj -Llib/armeabi-v7a -lraylib -lnative_app_glue -llog -landroid -lEGL -lGLESv2 -lOpenSLES -latomic -lc -lm -ldl

echo "Build script - Part 5"
$ANDROID_HOME/build-tools/29.0.3/aapt package -f -m -S res -J src -M AndroidManifest.xml -I $ANDROID_HOME/platforms/android-$ANDROID_API_VERSION/android.jar

echo "Build script - Part 6"
javac -verbose -source 1.8 -target 1.8 -d obj -bootclasspath /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/jre/lib/rt.jar -classpath $ANDROID_HOME/platforms/android-$ANDROID_API_VERSION/android.jar:obj -sourcepath src src/com/raylib_app/project/R.java src/com/raylib_app/project/NativeLoader.java

echo "Build script - Part 7"
$ANDROID_HOME/build-tools/29.0.3/dx --verbose --dex --output=dex/classes.dex obj

echo "Build script - Part 8"
$ANDROID_HOME/build-tools/29.0.3/aapt package -f -M AndroidManifest.xml -S res -A assets -I $ANDROID_HOME/platforms/android-$ANDROID_API_VERSION/android.jar -F project.unsigned.apk dex

echo "Build script - Part 9"
$ANDROID_HOME/build-tools/29.0.3/aapt add project.unsigned.apk lib/armeabi-v7a/libproject.so

echo "Build script - Part 10"
jarsigner -keystore project.keystore -storepass whatever -keypass whatever -signedjar project.signed.apk project.unsigned.apk projectKey

echo "Build script - Part 11"
$ANDROID_HOME/build-tools/29.0.3/zipalign -f 4 project.signed.apk project.apk

echo "Build script - Part 12"
$ANDROID_HOME/platform-tools/adb install -r project.apk
