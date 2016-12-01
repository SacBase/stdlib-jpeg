CMAKE_MINIMUM_REQUIRED (VERSION 3.3)

PROJECT (stdlib-jpeg)
#FIXME(artem) we can create a definitoin for language "SAC" which will
#             automatically pull sac2c compiler.

# Where the compiled sac modules result
SET (DLL_BUILD_DIR  "${PROJECT_BINARY_DIR}/lib")

# For what targets we build modules
SET (TARGETS            seq mt_pth  CACHE STRING "Build stdlib-jpeg for these targets")
SET (SAC2C_EXEC                     CACHE STRING "A path to sac2c compiler")
SET (LINKSETSIZE        "0"         CACHE STRING "Set a value for -linksetsize parameter of sac2c")
SET (SAC2C_EXTRA_INC    ""          CACHE STRING "Extra include files that should be used by sac2c")

# TODO figure out install and auto-dependencies


# Check whether sac2c is operational
INCLUDE ("cmake/check-sac2c.cmake")

# Check whether reqruired library is present on the system
INCLUDE ("cmake/check-jpeg.cmake")

# For every target run CMakeLists.txt in src
FOREACH (TARGET IN ITEMS ${TARGETS})
    ADD_SUBDIRECTORY (src   src-${TARGET})
ENDFOREACH ()
