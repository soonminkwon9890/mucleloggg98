allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all plugin subprojects to use Kotlin 2.0 language version and align
// the Kotlin JVM target to whatever Java target the Android plugin has already
// set for that subproject.  Using a task-graph callback (gradle.taskGraph) lets
// us read the finalised Java target without triggering "already evaluated" errors.
gradle.taskGraph.whenReady {
    subprojects.forEach { sub ->
        sub.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            // Read the Java target that AGP/the plugin already locked in, then
            // mirror it for Kotlin so both tasks agree on the JVM target.
            val javaTarget = sub.tasks
                .withType<JavaCompile>()
                .firstOrNull()
                ?.targetCompatibility
                ?: "17"
            val jvmTarget = when (javaTarget) {
                "1.8", "8"  -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "11"        -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                else        -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
            compilerOptions {
                this.jvmTarget.set(jvmTarget)
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
