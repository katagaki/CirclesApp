plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

fun loadProperties(filename: String): Map<String, String> {
    val properties = mutableMapOf<String, String>()
    val file = rootProject.file(filename)
    if (file.exists()) {
        file.reader().use { reader ->
            reader.buffered().forEachLine { line ->
                if (!line.startsWith("#") && line.contains("=")) {
                    val (key, value) = line.split("=", limit = 2)
                    properties[key.trim()] = value.trim()
                }
            }
        }
    }
    return properties
}

android {
    namespace = "com.tsubuzaki.circlesgo"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.tsubuzaki.circlesgo"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    signingConfigs {
        create("release") {
            val localProperties = loadProperties("local.properties")
            storeFile = localProperties["signing.storeFile"]?.let { file(it) }
            storePassword = localProperties["signing.storePassword"]
            keyAlias = localProperties["signing.keyAlias"]
            keyPassword = localProperties["signing.keyPassword"]
        }
    }

    buildTypes {
        debug {
            isDebuggable = true
            buildConfigField("String", "CIRCLEMS_AUTH_ENDPOINT", "\"https://auth1-sandbox.circle.ms\"")
            buildConfigField("String", "CIRCLEMS_API_ENDPOINT", "\"https://api1-sandbox.circle.ms\"")
        }
        release {
            isDebuggable = false
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            buildConfigField("String", "CIRCLEMS_AUTH_ENDPOINT", "\"https://auth1.circle.ms\"")
            buildConfigField("String", "CIRCLEMS_API_ENDPOINT", "\"https://api1.circle.ms\"")
        }
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.1"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    // Kotlin & Coroutines
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.serialization.json)

    // Ktor HTTP client
    implementation(libs.ktor.client.core)
    implementation(libs.ktor.client.okhttp)
    implementation(libs.ktor.client.content.negotiation)
    implementation(libs.ktor.serialization.kotlinx.json)

    // AndroidX Browser (Custom Tabs)
    implementation(libs.browser)

    // AndroidX Core
    implementation(libs.core.ktx)
    implementation(libs.lifecycle.runtime.ktx)
    implementation(libs.lifecycle.viewmodel.ktx)

    // Compose
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.material3.adaptive)
    implementation(libs.compose.material3.adaptive.layout)
    implementation(libs.compose.material3.adaptive.navigation)
    implementation(libs.compose.material.icons.extended)
    implementation(libs.activity.ktx)
    implementation(libs.material3)
}
