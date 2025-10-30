# Keep Twilio Video SDK and WebRTC classes used by JNI/reflection
-keep class com.twilio.** { *; }
-keep class tvi.webrtc.** { *; }
-keep class org.webrtc.** { *; }

# Prevent obfuscation of class and method names referenced from native code
-keepnames class com.twilio.**
-keepnames class tvi.webrtc.**
-keepnames class org.webrtc.**

# Suppress warnings for optional dependencies
-dontwarn com.twilio.**
-dontwarn tvi.webrtc.**
-dontwarn org.webrtc.**

# Keep annotations and signatures (sometimes used by reflection)
-keepattributes *Annotation*,Signature,EnclosingMethod,InnerClasses
