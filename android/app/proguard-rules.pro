# Flutter & Native JNI Methods
-keepclasseswithmembernames class * { native <methods>; }

# V2Ray / Xray Core & Go Runtime (libgojni.so)
-keep class com.v2ray.core.** { *; }
-keep class go.** { *; }

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }

# App Package & Flutter Engine
-keep class com.arshadevelop.izivpn.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Preserve Serializable & Models
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !static !transient <methods>;
    !private <methods>;
    <init>();
}
