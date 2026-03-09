# Market Hub - ProGuard Rules

# ─── Google Play Core (Flutter deferred components) ───────────────
# Flutter references these internally even if not used
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ─── Firebase ─────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# ─── Flutter ──────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─── Hive / Protobuf ─────────────────────────────────────────────
-keep class * extends com.google.protobuf.GeneratedMessageV3 { *; }
-dontwarn com.google.protobuf.**

# ─── Model classes ────────────────────────────────────────────────
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ─── Network stack (OkHttp / Dio) ─────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ─── WebSocket ────────────────────────────────────────────────────
-keep class org.java_websocket.** { *; }

# ─── Preserve debug info ─────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
