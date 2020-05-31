package com.raylib_app.project;
public class NativeLoader extends android.app.NativeActivity {
  static {
    System.loadLibrary("project"); // must match name of shared library (in this case libproject.so)
  }
}
