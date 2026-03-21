import java.io.File
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

fun loadEnv(name: String): Map<String, String> {
    val envFile = rootProject.file("../" + name)
    val env = mutableMapOf<String, String>()

    if (envFile.exists()) {
        envFile.forEachLine { line ->
            if (line.isNotBlank() && !line.startsWith("#") && line.contains("=")) {
                val parts = line.split("=", limit = 2)
                env[parts[0].trim()] = parts[1].trim()
            }
        }
    }
    return env
}

val stagingEnv = loadEnv(".env.staging")
val prodEnv = loadEnv(".env.prod")
val defaultEnv = loadEnv(".env")

fun resolveEnvValue(
    key: String,
    flavorEnv: Map<String, String>,
): String {
    val flavorValue = (flavorEnv[key] ?: "").trim()
    if (flavorValue.isNotEmpty()) {
        return flavorValue
    }
    val defaultValue = (defaultEnv[key] ?: "").trim()
    if (defaultValue.isNotEmpty()) {
        return defaultValue
    }
    return ""
}

val androidAdMobTestAppId = "ca-app-pub-3940256099942544~3347511713"

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.numverse.numverse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.numverse.numverse"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("prod") {
            dimension = "app"
            resValue(
                "string",
                "google_maps_api_key",
                resolveEnvValue("GOOGLE_MAP_API_KEY", prodEnv),
            )
            resValue(
                "string",
                "admob_app_id",
                resolveEnvValue("ADMOB_ANDROID_APP_ID", prodEnv).ifEmpty {
                    androidAdMobTestAppId
                },
            )
        }
        create("staging") {
            dimension = "app"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue(
                "string",
                "google_maps_api_key",
                resolveEnvValue("GOOGLE_MAP_API_KEY", stagingEnv),
            )
            resValue(
                "string",
                "admob_app_id",
                resolveEnvValue("ADMOB_ANDROID_APP_ID", stagingEnv).ifEmpty {
                    androidAdMobTestAppId
                },
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}
