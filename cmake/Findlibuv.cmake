find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(libuv IMPORTED_TARGET "libuv")
    if(TARGET PkgConfig::libuv AND NOT TARGET libuv::libuv)
        add_library(_libuv INTERFACE)
        target_link_libraries(_libuv INTERFACE PkgConfig::libuv)
        add_library(libuv::libuv ALIAS _libuv)
    endif()
endif()

if(NOT libuv_FOUND)
    find_path(libuv_INCLUDE_DIR uv.h)
    find_library(libuv_LIBRARY uv)

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(libuv
        REQUIRED_VARS libuv_INCLUDE_DIR libuv_LIBRARY
    )

    if(NOT TARGET libuv::libuv)
        add_library(libuv::libuv UNKNOWN IMPORTED)
        set_target_properties(libuv::libuv PROPERTIES
            IMPORTED_LOCATION "${libuv_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${libuv_INCLUDE_DIR}"
        )
    endif()
endif()
