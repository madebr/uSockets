find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(wolfssl IMPORTED_TARGET "wolfssl")
    if(TARGET PkgConfig::wolfssl AND NOT TARGET wolfssl::wolfssl)
        add_library(_wolfssl INTERFACE)
        target_link_libraries(_wolfssl INTERFACE PkgConfig::wolfssl)
        add_library(wolfssl::wolfssl ALIAS _wolfssl)
    endif()
endif()

if(NOT wolfssl_FOUND)
    find_path(wolfssl_INCLUDE_DIRS wolfssl/ssl.h)
    find_library(wolfssl_LIBRARY wolfssl)

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(wolfssl
        REQUIRED_VARS wolfssl_LIBRARY wolfssl_INCLUDE_DIRS
    )

    if(NOT TARGET wolfssl::wolfssl)
        add_library(wolfssl::wolfssl UNKNOWN IMPORTED)
        set_target_properties(wolfssl::wolfssl PROPERTIES
            IMPORTED_LOCATION "${wolfssl_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${wolfssl_INCLUDE_DIRS}"
        )
    endif()
endif()
