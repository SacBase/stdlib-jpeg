CMAKE_MINIMUM_REQUIRED (VERSION 3.3)
INCLUDE ("${CMAKE_SOURCE_DIR}/cmake/sac2c-variables.cmake")

SET (C_DEPS_SRC
  c-deps/jpeg.c
)

SET (SAC_SRC
    JPEG.sac
)


FUNCTION (RESOLVE_SAC_DEPENDENCIES f local_sources dep_lst ret_name)
    SET (ret)
    SET (local_file_list)
    SET (target_tree_output)
    SET (target_lib_output)

    # Create pathes to search libraries per given target
    STRING (REPLACE ":" ";" tree_dir_list "${TREE_OUTPUTDIR}")
    STRING (REPLACE ":" ";" lib_dir_list "${LIB_OUTPUTDIR}")
    FOREACH (p ${tree_dir_list})
        LIST (APPEND target_tree_output "${p}/${TARGET_ENV}/${SBI}")
    ENDFOREACH ()
    FOREACH (p ${lib_dir_list})
        LIST (APPEND target_lib_output "${p}/${TARGET_ENV}/${SBI}")
    ENDFOREACH ()

    # Create a list of *file names* by cutting away directory prefixes
    FOREACH (n ${local_sources})
        GET_FILENAME_COMPONENT (nn ${n} NAME)
        LIST (APPEND local_file_list "${nn}")
    ENDFOREACH ()

    # Filter dep_list
    FOREACH (dep ${dep_lst})
        # If dependency is a Mod or a Tree file
        STRING (REGEX MATCH "^lib(.+)(Mod|Tree)${TREE_DLLEXT}$" match "${dep}")
        IF (match)
            SET (n "${CMAKE_MATCH_1}")
            SET (libtype "${CMAKE_MATCH_2}")

            # Check if the same name can be found amongst the sources of the
            # current package.
            IF ("${n}.sac" IN_LIST ${local_file_list})
                # If so, keep it as a dependency.
                SET (d "${DLL_BUILD_DIR}/${TARGET_ENV}/${SBI}/${dep}")
                LIST (APPEND ret ${d})
            ELSE ()
                # Decide where do we need to look for the library
                SET (search_pathes ${target_lib_output})
                IF ("${libtype}" STREQUAL "Tree")
                    SET (search_pathes ${target_tree_output})
                ENDIF ()

                # If we didn't find DEP amongst local sac files, then it must
                # be an external dependency, in which case we search it via
                # FIND_LIBRARY.
                FIND_LIBRARY (
                    lib_found
                    NAMES ${dep}
                    HINTS ${search_pathes}
                    NO_DEFAULT_PATH)
                IF (NOT lib_found)
                    MESSAGE (FATAL_ERROR
                             "Exteral SAC module `${n}' which is required "
                             "to build `${f}' is not found!")
                ENDIF ()
            ENDIF ()
        ELSE ()
            # If DEP wasn't a sac module, check whether it is an object file.
            STRING (REGEX MATCH "${OBJEXT}$" match "${dep}")
            IF (match)
                # If so, add it to the list of dependencies
                LIST (APPEND ret "${CMAKE_CURRENT_BINARY_DIR}/${dep}")
            ENDIF ()
        ENDIF ()
    ENDFOREACH ()
    SET (${ret_name} ${ret} PARENT_SCOPE)
ENDFUNCTION ()


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

    # Resolve dependencies for the Module.
    EXECUTE_PROCESS (COMMAND ${SAC2C_T} -M ${src} OUTPUT_VARIABLE dep_str OUTPUT_STRIP_TRAILING_WHITESPACE)

    # XXX Currently this is correct, as sac2c always inserts '\n'.
    #     However, in case we ever support Windows, we might rethink this.
    STRING (REPLACE "\n" ";" dep_list "${dep_str}")
    RESOLVE_SAC_DEPENDENCIES ("${name}" "${SAC_SRC}" "${dep_list}" moddep_list)

    ADD_CUSTOM_COMMAND (
        OUTPUT ${mod} ${tree}
        COMMAND
            ${SAC2C} -v0 -linksetsize 0 -o ${DLL_BUILD_DIR} ${src}
        DEPENDS ${moddep_list}
        COMMENT "Building ${name} module for target `${TARGET}'")
    INSTALL (
        FILES ${mod}
        DESTINATION ${INSTALL_MOD_DIR}/${TARGET_ENV}/${SBI})
    INSTALL (
        FILES ${tree}
        DESTINATION ${INSTALL_TREE_DIR}/tree/${TARGET_ENV})
    ADD_CUSTOM_TARGET (${TARGET}-module-${dst} ALL DEPENDS ${mod} ${tree})
ENDFOREACH (name)

