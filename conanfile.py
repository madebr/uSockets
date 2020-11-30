from conans import CMake, ConanFile, tools
from conans.errors import ConanInvalidConfiguration
import textwrap


class USocketsConan(ConanFile):
    name = "usockets"
    description = "Miniscule cross-platform eventing, networking & crypto for async applications"
    homepage = "https://github.com/uNetworking/uSockets"

    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
        "crypto": [None, "openssl", "wolfssl"],
        "event": ["libuv", "gcd", "epoll", "kqueue"],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
        "crypto": "openssl",
        "event": "libuv",
        "wolfssl:opensslextra": True,
    }

    generators = "cmake", "pkg_config", "cmake_find_package"

    def export_source(self):
        self.copy("cmake")
        self.copy("CMakeLists.txt")
        self.copy("source")
        self.copy("examples")
        self.copy("tests")

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC
        if self.settings.os == "Linux":
            self.options.event = "epoll"
        if self.settings.os == "FreeBSD" or tools.is_apple_os(self.settings.os):
            self.options.event = "kqueue"

    def configure(self):
        if self.options.shared:
            del self.options.fPIC

    def requirements(self):
        if self.options.crypto == "openssl":
            self.requires("openssl/1.1.1h")
        elif self.options.crypto == "wolfssl":
            self.requires("wolfssl/4.5.0")
        if self.options.event == "libuv":
            self.requires("libuv/1.40.0")

    def build_requirements(self):
        self.build_requires("pkgconf/1.7.3")

    def build(self):
        if self.options.crypto == "wolfssl":
            if not self.options["wolfssl"].opensslextra:
                raise ConanInvalidConfiguration("uSockets requires wolfssl built with opensslextras")

        if self.source_folder == self.build_folder:
            raise RuntimeError("Cannot build with source_folder == build_folder ({} == {})".format(
                self.source_folder, self.build_folder))

        tools.save(
            "CMakeLists.txt",
            textwrap.dedent(
                """
                cmake_minimum_required(VERSION 3.0)
                project(cmake_wrapper)
                
                include("{}/conanbuildinfo.cmake")
                conan_basic_setup(TARGETS)
                
                add_subdirectory("{}" uSockets)
                """).format(
                    self.install_folder.replace("\\", "/"),
                    self.source_folder.replace("\\", "/"),
            )
        )
        cmake = CMake(self)
        cmake.definitions["USOCKETS_CRYPTO"] = str(self.options.crypto).upper()
        cmake.definitions["USOCKETS_EVENT"] = str(self.options.event).upper()
        cmake.configure(source_folder=self.build_folder)
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
