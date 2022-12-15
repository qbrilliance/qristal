# Copyright 2022 Quantum Brilliance
cmake_minimum_required(VERSION 3.20 FATAL_ERROR)

set(CORE_TAG main)
set(INTEGRATIONS_TAG main)
set(DECODER_TAG main)

# QB's core Gitlab repo ID (to fetch the add_dependency.cmake script)
# Default is the public repo.
set(QB_CORE_REPO_ID 41590729 CACHE STRING "QB SDK core Gitlab repository Id")
# Root Gitlab org. of SDK repos
set(QB_SDK_GITLAB_ORG qbau/software-and-apps/public CACHE STRING "QB SDK Gitlab group")

# Pre-retrieve core cmake dependency routines, for bootstrapping up to the full package.
file(DOWNLOAD https://gitlab.com/api/v4/projects/${QB_CORE_REPO_ID}/repository/files/cmake%2Fadd_dependency%2Ecmake/raw?ref=${CORE_TAG}
  ${CMAKE_CURRENT_LIST_DIR}/deps/add_dependency.cmake
  HTTPHEADER "PRIVATE-TOKEN: $ENV{GITLAB_PRIVATE_TOKEN}"
  STATUS STATUS_LIST)
list(POP_FRONT STATUS_LIST STATUS_LIST0)

if(STATUS_LIST0)
  message(FATAL_ERROR "Failed to download core. Please set environment variable GITLAB_PRIVATE_TOKEN.")
endif()

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/deps ${CMAKE_MODULE_PATH})
include(add_dependency)

# Project
project(QBSDK
  VERSION ${PROJECT_VERSION}
  DESCRIPTION "Quantum Brilliance Software Development Kit"
  LANGUAGES C CXX)

# Set default installation dir to the build dir
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR} CACHE PATH "..." FORCE)
endif()

# Set default RPATH to the lib dir of the installation dir
set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_PREFIX}/lib CACHE PATH "..." FORCE)

# Include CPM for managing dependencies, and set it up to cache them in the deps folder
set(CPM_DOWNLOAD_VERSION 0.36.0)
set(CPM_SOURCE_CACHE "${PROJECT_SOURCE_DIR}/deps")
set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")

if(NOT(EXISTS ${CPM_DOWNLOAD_LOCATION}))
  message(STATUS "Downloading CPM.cmake to ${CPM_DOWNLOAD_LOCATION}")
  file(DOWNLOAD
    https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
    ${CPM_DOWNLOAD_LOCATION}
  )
endif()

include(${CPM_DOWNLOAD_LOCATION})

# Get the core library
CPMAddPackage(
  NAME core
  GIT_TAG ${CORE_TAG} # Temporary (for rapid dev).
  GIT_SHALLOW False # Temporary (for rapid dev).
  GITLAB_REPOSITORY ${QB_SDK_GITLAB_ORG}/core
  SOURCE_DIR ${PROJECT_SOURCE_DIR}/core
  OPTIONS
    "CPM_SOURCE_CACHE ${CPM_SOURCE_CACHE}"
    "XACC_ROOT ${XACC_ROOT}"
    "EXATN_ROOT ${EXATN_ROOT}"
    "TNQVM_ROOT ${TNQVM_ROOT}"
)
check_missing()

# Get the integrations library
CPMAddPackage(
  NAME integrations
  GIT_TAG ${INTEGRATIONS_TAG} # Temporary (for rapid dev).
  GIT_SHALLOW False # Temporary (for rapid dev).
  GITLAB_REPOSITORY ${QB_SDK_GITLAB_ORG}/integrations
  SOURCE_DIR ${PROJECT_SOURCE_DIR}/integrations
)
check_missing()

# Get the decoder example
CPMAddPackage(
  NAME decoder
  GIT_TAG ${DECODER_TAG} # Temporary (for rapid dev).
  GIT_SHALLOW False # Temporary (for rapid dev).
  GITLAB_REPOSITORY ${QB_SDK_GITLAB_ORG}/decoder
  SOURCE_DIR ${PROJECT_SOURCE_DIR}/decoder
  OPTIONS
    "CPM_SOURCE_CACHE ${CPM_SOURCE_CACHE}"
    "CORE_ROOT ${PROJECT_SOURCE_DIR}/core"
    "QB_CORE_REPO_ID ${QB_CORE_REPO_ID}"
    "QB_SDK_GITLAB_ORG ${QB_SDK_GITLAB_ORG}"
)
check_missing()

# Print out the installation directory.
message(STATUS "Installation directory for ${PROJECT_NAME} set to ${CMAKE_INSTALL_PREFIX}.")

# Install the readme and exercises
install(
  DIRECTORY exercises
  DESTINATION ${CMAKE_INSTALL_PREFIX}
)

install(
  FILES README.md
  DESTINATION ${CMAKE_INSTALL_PREFIX}
)
