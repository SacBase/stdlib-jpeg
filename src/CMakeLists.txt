CMAKE_MINIMUM_REQUIRED (VERSION 3.3)
INCLUDE ("${CMAKE_SOURCE_DIR}/cmake/sac2c-variables.cmake")
INCLUDE ("${CMAKE_SOURCE_DIR}/cmake/resolve-sac2c-dependencies.cmake")

SET (C_DEPS_SRC
  c-deps/jpeg.c
)

SET (SAC_SRC
    JPEG.sac
)

# TODO(artem) We may want to introduce a mechanism of generating depenencies
#             on a given sac2c versoin.  That is, recompiler all modules if
#             sac2c version changes.


# For every C source, compile an object file maintaining the right location
# in the binary dir so that sac files can pick it up.
# XXX do we ever pass some extra flags, etc to C files?
FOREACH(name ${C_DEPS_SRC})
  SET (src "${CMAKE_CURRENT_SOURCE_DIR}/${name}")
  GET_FILENAME_COMPONENT (dst ${name} NAME_WE)
  GET_FILENAME_COMPONENT (dir ${name} DIRECTORY)
  FILE (MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${dir}")
  SET (dst "${CMAKE_CURRENT_BINARY_DIR}/${dir}/${dst}${OBJEXT}")
  ADD_CUSTOM_COMMAND (
    OUTPUT "${dst}"
    DEPENDS "${src}"
    COMMAND ${SAC2C} -v0 -noprelude -cc ccmod -o "${dst}" "${src}"
    COMMENT "Generating ${dst}"
  )
ENDFOREACH(name)

# Make a directory for sac2c output
FILE (MAKE_DIRECTORY "${DLL_BUILD_DIR}/${TARGET_ENV}/${SBI}")

# For every sac file, compile Tree and Mod files.
FOREACH (name ${SAC_SRC})
    SET (src "${CMAKE_CURRENT_SOURCE_DIR}/${name}")
    GET_FILENAME_COMPONENT (dst ${name} NAME_WE)
    SET (mod
        "${DLL_BUILD_DIR}/${TARGET_ENV}/${SBI}/lib${dst}Mod${MODEXT}")
    SET (tree
        "${DLL_BUILD_DIR}/tree/${TARGET_ENV}/lib${dst}Tree${TREE_DLLEXT}")

    RESOLVE_SAC_DEPENDENCIES ("${src}" "${SAC_SRC}" moddep_list)

    MESSAGE ("dependencies of ${name} => `${moddep_list}'")

    ADD_CUSTOM_COMMAND (
        OUTPUT ${mod} ${tree}
        COMMAND
            ${SAC2C} -v0 -linksetsize 0 -o ${DLL_BUILD_DIR} ${src}
        DEPENDS ${moddep_list}
        COMMENT "Building ${name} module for target `${TARGET}'")

    # Install compiled Tree/Mod parts of the compiled module
    # to the corresponding locations.
    INSTALL (
        FILES ${mod}
        DESTINATION ${INSTALL_MOD_DIR}/${TARGET_ENV}/${SBI})
    INSTALL (
        FILES ${tree}
        DESTINATION ${INSTALL_TREE_DIR}/tree/${TARGET_ENV})

    # Make a call to the command that compiles the module a part
    # of the default build process.
    ADD_CUSTOM_TARGET (${TARGET}-module-${dst} ALL DEPENDS ${mod} ${tree})
ENDFOREACH (name)

