allprojects {
    repositories {
        // ZEGOCLOUD maven (chứa zpns + plugin push)
        maven(url = "https://storage.zego.im/maven")
        maven(url = "https://storage.zego.im/downloads/maven")
        maven(url = "https://storage.zego.im/downloads/maven-repo")
        maven(url = "https://maven.zego.im")
        maven(url = "https://jitpack.io")
        // Huawei/Heytap repo để tránh lỗi thiếu dependencies khi bật push vendor khác
        maven(url = "https://developer.huawei.com/repo/")
        maven {
            url = uri("https://maven.columbus.heytapmobi.com/repository/releases/")
            credentials {
                username = "nexus"
                password = "c0b08da17e3ec36c3870fed674a0bcb36abc2e23"
            }
        }
        google()
        mavenCentral()
    }
}

// Nếu plugin nào đó vẫn yêu cầu artifact tên cũ, map sang artifact mới của Zego.
allprojects {
    configurations.all {
        resolutionStrategy.dependencySubstitution {
            substitute(module("im.zego:zpns_android_plugin_fcm")) using
                module("im.zego:zpns-fcm:2.8.2")
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
