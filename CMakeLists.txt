# Copyright 2022 Quantum Brilliance

# Set minimum cmake version
set(MIN_CMAKE_VERSION 3.20)
cmake_minimum_required(VERSION ${MIN_CMAKE_VERSION} FATAL_ERROR)

# Dependencies
set(CORE_VERSION          "1.0.0")
set(INTEGRATIONS_VERSION  "1.0.0")
set(DECODER_VERSION       "1.0.0")

if(NOT DEFINED CORE_TAG)
  set(CORE_TAG v${CORE_VERSION})
endif()
if(NOT DEFINED INTEGRATIONS_TAG)
  set(INTEGRATIONS_TAG v${INTEGRATIONS_VERSION})
endif()
if(NOT DEFINED DECODER_TAG)
  set(DECODER_TAG v${DECODER_VERSION})
endif()

# Note that you can set -DCORE_TAG=<tag> to a branch, tag or SHA if you want to download and use a specific commit of the core. Same for integrations and decoder.

# Get version number from git tag.  Must be done before the project command is called.
find_package(Git)
if(GIT_FOUND)
  execute_process(
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND git describe --tags --abbrev=0
    OUTPUT_VARIABLE PROJECT_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  string(REGEX REPLACE "^v(.*)" "\\1" PROJECT_VERSION "${PROJECT_VERSION}")
endif()

# Project
project(qristal
  VERSION ${PROJECT_VERSION}
  DESCRIPTION "Qristal: Quantum Brilliance Software Development Kit"
  LANGUAGES C CXX
)

# Choose C++ standard version
set(CMAKE_CXX_STANDARD 17 CACHE STRING "Adopted C++ standard.")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set default installation dir to the build dir.
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR} CACHE PATH "Installation path." FORCE)
  set(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OFF)
endif()
message(STATUS "Installation directory for ${PROJECT_NAME} set to ${CMAKE_INSTALL_PREFIX}.")

# Work out build type
set(CMAKE_BUILD_TYPE "None" CACHE STRING "Type of build: None, Release, Debug, RelWithDebInfo or MinSizeRel." FORCE)
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "None" "Debug" "Release" "MinSizeRel" "RelWithDebInfo")

# Include CPM for managing dependencies, and set it up to cache them in the deps folder.
set(CPM_DOWNLOAD_VERSION 0.36.0)
set(CPM_SOURCE_CACHE "${CMAKE_CURRENT_LIST_DIR}/deps" CACHE PATH "Dependencies path.")
set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
if(NOT (EXISTS ${CPM_DOWNLOAD_LOCATION}))
  message(STATUS "Downloading CPM.cmake to ${CPM_DOWNLOAD_LOCATION}")
  file(DOWNLOAD
       https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
       ${CPM_DOWNLOAD_LOCATION}
  )
endif()
include(${CPM_DOWNLOAD_LOCATION})

# Find the core
find_package(qbcore ${CORE_VERSION} QUIET)

# Try to install the core if it wasn't found.
if (NOT qbcore_FOUND)

  if (NOT INSTALL_MISSING)
    message(FATAL_ERROR "Could not find core ${CORE_VERSION}. Please set qbcore_DIR to its installed location, or pass -DINSTALL_MISSING=ON (or =CXX or =PYTHON).")
  endif()

  # Root Gitlab org. of SDK repos
  set(QB_SDK_GITLAB_ORG qbau/software-and-apps/public CACHE STRING "QB SDK Gitlab group")

  # Get the core
  CPMAddPackage(
    NAME core
    VERSION ${CORE_VERSION}
    GIT_TAG ${CORE_TAG}
    GIT_SHALLOW False # Temporary (for rapid dev).
    GITLAB_REPOSITORY ${QB_SDK_GITLAB_ORG}/core
    SOURCE_DIR ${PROJECT_SOURCE_DIR}/core
    OPTIONS
      "INSTALL_MISSING ${INSTALL_MISSING}"
      "CPM_SOURCE_CACHE ${CPM_SOURCE_CACHE}"
      "CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}"
      "XACC_ROOT ${XACC_ROOT}"
      "EXATN_ROOT ${EXATN_ROOT}"
      "TNQVM_ROOT ${TNQVM_ROOT}"
      "WITH_TKET ${WITH_TKET}"
      "TKET_DIR ${TKET_DIR}"
      "BUILD_DOCS ${BUILD_DOCS}"
      "WARNINGS ${WARNINGS}"
  )
  include(CMakeFindDependencyMacro)
  include(${CMAKE_CURRENT_BINARY_DIR}/_deps/core-build/coreDependencies.cmake)
  set(qbcore_DIR ${core_SOURCE_DIR})

endif()

# Set default RPATH to the lib dir of the installation dir.
set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_PREFIX}/${qbcore_LIBDIR} CACHE PATH "Search path for shared libraries to encode into binaries." FORCE)

# Get the integrations library
CPMAddPackage(
  NAME integrations
  GIT_TAG ${INTEGRATIONS_TAG} # Temporary (for rapid dev).
  GIT_SHALLOW False # Temporary (for rapid dev).
  GITLAB_REPOSITORY ${QB_SDK_GITLAB_ORG}/integrations
  SOURCE_DIR ${PROJECT_SOURCE_DIR}/integrations
)

# Get the decoder example
CPMAddPackage(
  NAME decoder
  GIT_TAG ${DECODER_TAG} # Temporary (for rapid dev).
  GIT_SHALLOW False # Temporary (for rapid dev).
  GITLAB_REPOSITORY ${QB_SDK_GITLAB_ORG}/decoder
  SOURCE_DIR ${PROJECT_SOURCE_DIR}/decoder
  OPTIONS
    "CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}"
    "WARNINGS ${WARNINGS}"
    "SKIP_FIND_CORE ON"
    "qbcore_FOUND ON"
)

# Install the readme and exercises
install(
  DIRECTORY exercises
  DESTINATION ${CMAKE_INSTALL_PREFIX}
)

install(
  FILES README.md
  DESTINATION ${CMAKE_INSTALL_PREFIX}
)

# If the core was found elsewhere, create symlinks to all the installed content
if (qbcore_FOUND)
  file(GLOB_RECURSE CORE_INSTALL_FILES RELATIVE ${qbcore_DIR} ${qbcore_DIR}/*)
  foreach(installed_file ${CORE_INSTALL_FILES})
    cmake_path(GET installed_file PARENT_PATH path)
    install(CODE "execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_INSTALL_PREFIX}/${path})")
    install(CODE "execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${qbcore_DIR}/${installed_file} ${CMAKE_INSTALL_PREFIX}/${installed_file})")
  endforeach()
endif()
