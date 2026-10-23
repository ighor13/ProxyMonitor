cmake_minimum_required(VERSION 3.16)
project(ProxyMonitor VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Network Qml QuickControls2)

qt_standard_project_setup(REQUIRES 6.5)

# Убираем предупреждение QTP0002 для Android
if(QT_KNOWN_POLICY_QTP0002)
    qt_policy(SET QTP0002 NEW)
endif()

qt_add_executable(ProxyMonitor
    main.cpp
    proxytest.cpp
    proxytest.h
)

qt_add_qml_module(ProxyMonitor
    URI ProxyMonitor
    VERSION 1.0
    QML_FILES
        main.qml
        ProxySplash.qml
        ProxyMain.qml
        SettingsPage.qml
)

target_link_libraries(ProxyMonitor PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Network
    Qt6::Qml
    Qt6::QuickControls2
)

if(ANDROID)
    include(FetchContent)
    FetchContent_Declare(
        android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(ProxyMonitor)

    qt_add_android_permission(ProxyMonitor NAME "android.permission.INTERNET")
endif()