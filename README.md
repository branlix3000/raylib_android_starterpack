# Raylib Android Starter Kit

Launching `start.sh` will get you started, as fast as possible, to develop your first Android application using Raylib.

The script just reproduce all the necessary steps to download the Android SDK and NDK, compile the Raylib library for Android, and compile a Raylib sample application into an APK.

This script has been developped under Arch Linux, with the latest Android SDK and NDK.

Modifying the file `src/Makefile` in the `raylib` directory may be necessary, this way:

```
diff --git a/src/Makefile b/src/Makefile
index HEAD^..HEAD 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -168,8 +168,8 @@ ifeq ($(PLATFORM),PLATFORM_ANDROID)
         ANDROID_NDK = C:/android-ndk-r21
         ANDROID_TOOLCHAIN = $(ANDROID_NDK)/toolchains/llvm/prebuilt/windows-x86_64
     else
-        ANDROID_NDK = /usr/lib/android/ndk
-        ANDROID_TOOLCHAIN = $(ANDROID_NDK)/toolchains/llvm/prebuilt/linux
+        ANDROID_NDK ?= /usr/lib/android/ndk
+        ANDROID_TOOLCHAIN = $(ANDROID_NDK)/toolchains/llvm/prebuilt/linux-x86_64
     endif

     ifeq ($(ANDROID_ARCH),ARM)
```

Pull requests are welcome.
