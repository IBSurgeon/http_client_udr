# ---------------------------------------------------------------------------
# IBSurgeon Http Client UDR Library.
#
# The original code was created by Simonov Denis
# for project "IBSurgeon Http Client UDR".
#
# Copyright (c) 2023 Simonov Denis <sim-mail@list.ru>
# and all contributors signed below.
#
# All Rights Reserved.
# Contributor(s): ______________________________________.
# ----------------------------------------------------------------------------


cmake_minimum_required(VERSION 3.6)

project(http_client_udr
    LANGUAGES CXX
    VERSION 1.0.0)

###############################################################################
# CMake standard options
############

option(BUILD_SHARED_LIBS "Build shared library" ON)

set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR}/build)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

###############################################################################
# Require and enable C++ 0x/11/14
############
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
message(STATUS "${PROJECT_NAME} compile: C++${CMAKE_CXX_STANDARD}")

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_COMPILER_IS_GNUCXX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wnarrowing -Werror")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -s")
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag("-stdlib=libc++" CXX_SUPPORTS_STDLIB)
    if(CXX_SUPPORTS_STDLIB)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -stdlib=libc++")
        set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -stdlib=libc++")
    endif()	
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
    string(REGEX REPLACE "[/-]W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    if (NOT (CMAKE_VERSION VERSION_LESS 3.6.0)) # Compiler features for Intel in CMake 3.6+
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Qstd=c++14")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /QaxCORE-AVX2")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /fp:precise")
    set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG}   /Od")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O3")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Qipo")
elseif(MSVC)
    string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    if(MSVC_VERSION LESS 1900)
        message(FATAL_ERROR "${PROJECT_NAME} build: Build requires C++17-compliant compiler")
    endif()
endif()

if(CMAKE_BUILD_TYPE MATCHES Debug)
	message(STATUS "${PROJECT_NAME} build: compiler flags - ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_DEBUG}")
elseif(CMAKE_BUILD_TYPE MATCHES Release)
	message(STATUS "${PROJECT_NAME} build: compiler flags - ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE}")
endif()

####################################
# src
####################################
file(GLOB_RECURSE sources "src/*")
add_library(http_client_udr SHARED ${sources}) 

set(FIREBIRD_DIR /opt/firebird)
set(FIREBIRD_INCLUDE_DIR ${FIREBIRD_DIR}/include)
set(FIREBIRD_LIB_DIR ${FIREBIRD_DIR}/lib)
set(FIREBIRD_UDR_DIR ${FIREBIRD_DIR}/plugins/udr)

include_directories(${FIREBIRD_INCLUDE_DIR})


find_package(CURL REQUIRED)

include_directories(${CURL_INCLUDE_DIR})
target_link_libraries(${PROJECT_NAME}  ${CURL_LIBRARY})


install(TARGETS ${PROJECT_NAME}  DESTINATION ${FIREBIRD_UDR_DIR})
install(FILES "sql/http_client_install.sql"
              DESTINATION ${FIREBIRD_UDR_DIR})


