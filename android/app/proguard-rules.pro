# ═══════════════════════════════════════════════════
# ProGuard Rules — KreaSea
# ═══════════════════════════════════════════════════

# ── Flutter ──────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase Core ─────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Firebase Auth ─────────────────────────────────────
-keep class com.google.firebase.auth.** { *; }
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# ── Firestore ─────────────────────────────────────────
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# ── Google Sign-In ────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ── Firebase Storage ──────────────────────────────────
-keep class com.google.firebase.storage.** { *; }

# ── Kotlin ────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# ── Gson / JSON ───────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# ── OkHttp (used by Firebase) ─────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
