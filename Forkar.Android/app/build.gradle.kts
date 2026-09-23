import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.cokistudios.forkar"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.cokistudios.forkar"
        minSdk = 26
        targetSdk = 34
        versionCode = 6
        versionName = "3.0.3"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    signingConfigs {
        getByName("debug") {
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
            enableV4Signing = false
        }
        create("release") {
            val ksRelPath = if (hasKeystore) keystoreProperties.getProperty("storeFile", "keystore/forkar-release.jks") else "keystore/forkar-release.jks"
            val ksFile = rootProject.file(ksRelPath)
            if (ksFile.exists()) {
                storeFile = ksFile
                storePassword = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD") ?: "CokiStudiosForkar2026!"
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS") ?: "forkar_release"
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD") ?: "CokiStudiosForkar2026!"
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
                enableV4Signing = false
            } else {
                val fallbackFile = rootProject.file("keystore/ci-fallback.jks")
                if (!fallbackFile.exists()) {
                    fallbackFile.parentFile?.mkdirs()
                    try {
                        val keytoolBin = org.gradle.internal.jvm.Jvm.current().javaHome.resolve("bin/keytool").absolutePath
                        val cmd = listOf(
                            keytoolBin, "-genkeypair",
                            "-alias", "ci_fallback",
                            "-keyalg", "RSA",
                            "-keysize", "2048",
                            "-validity", "10000",
                            "-keystore", fallbackFile.absolutePath,
                            "-storepass", "android",
                            "-keypass", "android",
                            "-dname", "CN=CI Fallback, O=Coki Studios, C=CO"
                        )
                        ProcessBuilder(cmd).start().waitFor()
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                if (fallbackFile.exists()) {
                    storeFile = fallbackFile
                    storePassword = "android"
                    keyAlias = "ci_fallback"
                    keyPassword = "android"
                    enableV1Signing = true
                    enableV2Signing = true
                    enableV3Signing = true
                    enableV4Signing = false
                }
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    flavorDimensions += "channel"
    productFlavors {
        create("production") {
            dimension = "channel"
            applicationId = "com.cokistudios.forkar"
            buildConfigField("String", "CHANNEL_NAME", "\"production\"")
            buildConfigField("Boolean", "IS_QA", "false")
            buildConfigField("Boolean", "IS_INTERNAL_CS", "false")
        }
        create("qa") {
            dimension = "channel"
            applicationIdSuffix = ".qa"
            versionNameSuffix = "-qa"
            buildConfigField("String", "CHANNEL_NAME", "\"qa\"")
            buildConfigField("Boolean", "IS_QA", "true")
            buildConfigField("Boolean", "IS_INTERNAL_CS", "false")
        }
        create("internal") {
            dimension = "channel"
            applicationIdSuffix = ".internal"
            versionNameSuffix = "-cs"
            buildConfigField("String", "CHANNEL_NAME", "\"internal\"")
            buildConfigField("Boolean", "IS_QA", "false")
            buildConfigField("Boolean", "IS_INTERNAL_CS", "true")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.10"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    
    // Compose Navigation
    implementation("androidx.navigation:navigation-compose:2.7.7")
    
    // HTTP Connection & JSON Serialization
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.code.gson:gson:2.10.1")
    
    // Image loading (Coil)
    implementation("io.coil-kt:coil-compose:2.5.0")

    // Firebase Platform (BoM) & Analytics / App Testing
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-appdistribution-api:16.0.0-beta20")
    "qaImplementation"("com.google.firebase:firebase-appdistribution:16.0.0-beta20")

    // Tooling
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
