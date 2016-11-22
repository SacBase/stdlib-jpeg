INCLUDE ("${CMAKE_SOURCE_DIR}/cmake/sac2c-variables.cmake")

SET (C_DEPS_SRC
  c-deps/jpeg.c
)

SET (SAC_SRC
    JPEG.sac
)

# List of dependent objects
SET(C_DEPS_OBJS)

# For every C source, compile an object file maintaining the right location
# in the binary dir so that sac files can pick it up.  Put object files in the
# C_DEPS_OBJS to be used as a dependency for sac files.
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
  LIST (APPEND C_DEPS_OBJS "${dst}")
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
        "${DLL_BUILD_DIR}/${TARGET_ENV}/${SBI}/lib${dst}Tree${TREE_DLLEXT}")
    ADD_CUSTOM_COMMAND (
        OUTPUT ${mod} ${tree}
        COMMAND
            ${SAC2C} -v0 -linksetsize 0 -o ${DLL_BUILD_DIR} ${src}
        DEPENDS ${C_DEPS_OBJS}
        COMMENT "Building ${name} module for target `${TARGET}'")
    ADD_CUSTOM_TARGET (${TARGET}-module-${dst} ALL DEPENDS ${mod} ${tree})
ENDFOREACH (name)

