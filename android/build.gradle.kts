allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround for legacy plugins that don't specify namespace in build.gradle
// Required for AGP 8+ compatibility
subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.LibraryExtension) {
            if (androidExtension.namespace.isNullOrEmpty()) {
                val manifestFile = file("${projectDir}/src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = groovy.xml.XmlSlurper().parse(manifestFile)
                    val packageName = manifest.getProperty("@package")?.toString()
                    if (!packageName.isNullOrEmpty()) {
                        androidExtension.namespace = packageName
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
