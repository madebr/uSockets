cmake_minimum_required(VERSION 3.9)
project(uSockets)

# For now we need to link with C++ for OpenSSL support, but should be removed with time
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "RelWithDebInfo")
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(USOCKETS_CRYPTO_BACKENDS "NONE;OPENSSL;WOLFSSL")
set(USOCKETS_EVENT_BACKENDS "LIBUV")
set(USOCKETS_EVENT_DEFAULT "LIBUV")
if(APPLE)
    list(APPEND USOCKETS_EVENT_BACKENDS GCD KQUEUE)
    set(USOCKETS_EVENT_DEFAULT "KQUEUE")
endif()
if(APPLE OR CMAKE_SYSTEM_NAME MATCHES ".*BSD")
    list(APPEND USOCKETS_EVENT_BACKENDS KQUEUE)
endif()
if(CMAKE_SYSTEM_NAME MATCHES ".*BSD")
    set(USOCKETS_EVENT_DEFAULT "KQUEUE")
endif()
if(NOT WIN AND NOT APPLE)
    list(APPEND USOCKETS_EVENT_BACKENDS EPOLL)
endif()

set(USOCKETS_CRYPTO "NONE" CACHE STRING "Crypto backend of uSockets.")
set_property(CACHE USOCKETS_CRYPTO PROPERTY STRINGS "${USOCKETS_CRYPTO_BACKENDS}")

set(USOCKETS_EVENT "${USOCKETS_EVENT_DEFAULT}" CACHE STRING "Eventloop backend of uSockets.")
set_property(CACHE USOCKETS_EVENT PROPERTY STRINGS "${USOCKETS_EVENT_BACKENDS}")

option(USOCKETS_ASAN "build with addres sanitizers")
option(USOCKETS_EXAMPLES "build examples" ON)
option(USOCKETS_LTO "build with LTO" ON)
option(USOCKETS_PIC "build with PIC" ON)

if(NOT USOCKETS_CRYPTO IN_LIST USOCKETS_CRYPTO_BACKENDS)
    message(FATAL_ERROR "Illegal usocket crypto backend (${USOCKETS_CRYPTO})
    Available backends are: ${USOCKETS_CRYPTO_BACKEND}")
endif()

if(NOT USOCKETS_EVENT IN_LIST USOCKETS_EVENT_BACKENDS)
    message(FATAL_ERROR "Illegal usocket eventloop backend (${USOCKETS_EVENT})
    Available backends are: ${USOCKETS_EVENT_BACKENDS}")
endif()

add_library(uSockets
    src/context.c
    src/socket.c
    src/bsd.c
    src/loop.c

    src/crypto/sni_tree.cpp
    src/crypto/openssl.c
    src/crypto/wolfssl.c

    src/eventing/libuv.c
    src/eventing/gcd.c
    src/eventing/epoll_kqueue.c
)
target_include_directories(uSockets PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>)

if(USOCKETS_CRYPTO STREQUAL "OPENSSL")
    find_package(OpenSSL REQUIRED)
    target_compile_definitions(uSockets PUBLIC LIBUS_USE_OPENSSL)
    target_link_libraries(uSockets PRIVATE OpenSSL::SSL)
elseif(USOCKETS_CRYPTO STREQUAL "WOLFSSL")
    find_package(WolfSSL REQUIRED)
    target_compile_definitions(uSockets PUBLIC LIBUS_USE_WOLFSSL)
    target_link_libraries(uSockets PRIVATE WolfSSL::WolfSSL)
else()
    target_compile_definitions(uSockets PUBLIC LIBUS_NO_SSL)
endif()

if(USOCKETS_EVENT STREQUAL "LIBUV")
    find_package(libuv REQUIRED)
    target_compile_definitions(uSockets PRIVATE LIBUS_USE_LIBUV)
    target_link_libraries(uSockets PRIVATE libuv::libuv)
elseif(USOCKETS_EVENT STREQUAL "GCD")
    target_link_libraries(uSockets PRIVATE "-framework CoreFoundation")
    target_compile_definitions(uSockets PUBLIC LIBUS_USE_GCD)
elseif(USOCKETS_EVENT STREQUAL "EPOLL")
    target_compile_definitions(uSockets PUBLIC LIBUS_USE_EPOLL)
elseif(USOCKETS_EVENT STREQUAL "KQUEUE")
    target_compile_definitions(uSockets PUBLIC LIBUS_USE_KQUEUE)
endif()

if(USOCKETS_ASAN)
    target_compile_options(uSockeets PUBLIC "-fsanitize=address")
    target_link_options(uSockeets PUBLIC "-fsanitize=address")
endif()

if(USOCKETS_LTO)
    include(CheckIPOSupported)
    check_ipo_supported()
    set_property(TARGET uSockets PROPERTY INTERPROCEDURAL_OPTIMIZATION ON)
endif()

set_property(TARGET uSockets PROPERTY POSITION_INDEPENDENT_CODE ${USOCKETS_PIC})

if(USOCKETS_EXAMPLES)
    file(GLOB EXAMPLE_SOURCES "examples/*.c")
    foreach(EXAMPLE_SOURCE ${EXAMPLE_SOURCES})
        get_filename_component(EXAMPLE_NAME "${EXAMPLE_SOURCE}" NAME_WE)
        add_executable(${EXAMPLE_NAME} ${EXAMPLE_SOURCE})
        target_link_libraries(${EXAMPLE_NAME} PRIVATE uSockets)
    endforeach()
endif()

if(XCODE)
    enable_language(Swift)
    add_executable(swift_http_server examples/swift_http_server/main.swift)
    target_link_libraries(swift_http_server PRIVATE uSockets)
endif()
