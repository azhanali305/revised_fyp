# Gson / flutter_local_notifications
# Required when using R8/ProGuard with older Gson versions.

-keepattributes Signature
-keepattributes *Annotation*

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken