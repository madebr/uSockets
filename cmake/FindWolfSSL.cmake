find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(WolfSSL IMPORTED_TARGET "wolfssl")
    if(TARGET PkgConfig::WolfSSL AND NOT TARGET libuv::libuv)
        add_library(_wolfssl INTERFACE)
        target_link_libraries(_wolfssl INTERFACE PkgConfig::WolfSSL)
        add_library(WolfSSL::WolfSSL ALIAS _wolfssl)
    endif()
endif()

if(NOT WolfSSL_FOUND)
    find_path(WolfSSL_INCLUDE_DIRS wolfssl/ssl.h)
    find_library(WolfSSL_LIBRARY wolfssl)

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(WolfSSL
        REQUIRED_VARS WolfSSL_INCLUDE_DIRS WolfSSL_LIBRARY
    )

    if(NOT TARGET WolfSSL::WolfSSL)
        add_library(WolfSSL::WolfSSL UNKNOWN IMPORTED)
        set_target_properties(WolfSSL::WolfSSL PROPERTIES
            IMPORTED_LOCATION "${WolfSSL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${WolfSSL_INCLUDE_DIRS}"
        )
    endif()
endif()
