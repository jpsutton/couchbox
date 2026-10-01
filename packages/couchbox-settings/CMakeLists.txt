# SPDX-License-Identifier: MIT
cmake_minimum_required(VERSION 3.22)
project(kcm_mediacenter_couchbox LANGUAGES CXX)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Qml Quick)
find_package(KF6 6.0 REQUIRED COMPONENTS Config CoreAddons KCMUtils)

# Installs to plasma/kcms/systemsettings, where Bigscreen Settings lists every
# KCM whose metadata has FormFactors "mediacenter". ui/ is embedded.
kcmutils_add_qml_kcm(kcm_mediacenter_couchbox SOURCES couchbox.cpp)
target_link_libraries(kcm_mediacenter_couchbox PRIVATE KF6::ConfigCore KF6::CoreAddons KF6::KCMUtilsQuick)
