allprojects {
    repositories {
        google()
        mavenCentral()
       val flutterProjectRoot = rootProject.projectDir.parentFile.absolutePath
        maven {
            // String di Kotlin Script menggunakan tanda petik yang benar
            url = uri("$flutterProjectRoot/.pub-cache/hosted/pub.dev")
        } 
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
