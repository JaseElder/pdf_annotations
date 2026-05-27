import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
}

group = "com.loucheindustries.pdf_annotations"
version = "1.0-SNAPSHOT"

android {
    namespace = "com.loucheindustries.pdf_annotations"

    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("proguard-rules.pro")
    }

    dependencies {
        implementation("com.tom-roush:pdfbox-android:2.0.27.0")
        testImplementation("org.jetbrains.kotlin:kotlin-test")
        testImplementation("org.mockito:mockito-core:5.23.0")
    }

    testOptions {
        unitTests.all {
            it.useJUnitPlatform()

            it.testLogging {
               events("passed", "skipped", "failed", "standardOut", "standardError")
               showStandardStreams = true
            }
            it.outputs.upToDateWhen {false}
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}