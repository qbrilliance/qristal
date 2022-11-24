# Copyright 2022 Quantum Brilliance
cmake_minimum_required(VERSION 3.20 FATAL_ERROR)

set(CORE_TAG main)
set(INTEGRATIONS_TAG main)
set(DECODER_TAG main)

# Pre-retrieve core cmake dependency routines, for bootstrapping up to the full package.
file(DOWNLOAD https://gitlab.com/api/v4/projects/39963594/repository/files/cmake%2Fadd_dependency%2Ecmake/raw?ref=${CORE_TAG}
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
set(CPM_SOURCE_CACHE "${PROJECT_SOURCE_DIR}")
set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/deps/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")

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
  GITLAB_REPOSITORY qbau/software-and-apps/core
)
check_missing()

# Get the integrations library
CPMAddPackage(
  NAME integrations
  GIT_TAG ${INTEGRATIONS_TAG} # Temporary (for rapid dev).
  GIT_SHALLOW False # Temporary (for rapid dev).
  GITLAB_REPOSITORY qbau/software-and-apps/integrations
)
check_missing()

# Get the decoder example
CPMAddPackage(
  NAME decoder
  GIT_TAG ${DECODER_TAG} # Temporary (for rapid dev).
  GIT_SHALLOW False # Temporary (for rapid dev).
  GITLAB_REPOSITORY qbau/software-and-apps/decoder
)
check_missing()

# Print out the installation directory.
message(STATUS "Installation directory for ${CMAKE_PROJECT_NAME} set to ${CMAKE_INSTALL_PREFIX}.")
