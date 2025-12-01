# --- ML Kit Text Recognition Keep Rules ---

# Keep all ML Kit Vision classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep Text Recognition models (Chinese, Japanese, Korean, Devanagari)
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
