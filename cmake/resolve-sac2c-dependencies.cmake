# This file deals with checking/resolving dependencies of the given
# sac file.
#
# Assumptions:
#   * DLL_BUILD_DIR has been previously defined.
#   * `sac2c-variables.cmake' has been included.


# Sanity check.  DLL_BUILD_DIR is the location where to put compiled
# sac modules.  This is needed to generate local dependency correctly.
IF (NOT DLL_BUILD_DIR)
    MESSAGE (FATAL_ERROR "The DLL_BUILD_DIR variable is not set")
ENDIF ()

# Sanity check.  SAC-related variables like SBI, TARGET_ENV, etc
# are defined in the sac2c-variables.cmake which should be included
# before including this file.
IF (NOT SBI)
    MESSAGE (FATAL_ERROR "The SBI variable is not set. (consider including sac2c-variables.cmake?)")
ENDIF ()


# This function for a given sac source file `file_name' calls
# `${SAC2C_T} -M ${file_name}', and:
#
#   * for Mod/Tree files, if a file can be found amongst the sources,
#     we add it to the list of local dependencies;
#     otherwise, this is an external dependency --- we check wether
#     such a file exists on ${TREE_OUTPUT_DIR}/${LIB_OUTPUT_DIR}
#     and if it doesn't a failure is generated.
#   * object files are added to the dependency list;
#   * -l<name> dependencies are ignored.
#
# The function stores list of local dependencies to the variable `${ret_name}'.
FUNCTION (RESOLVE_SAC_DEPENDENCIES file_name local_sources ret_name)
    SET (ret)
    SET (local_file_list)
    SET (target_tree_output)
    SET (target_lib_output)

    # Resolve dependencies for the Module.
    EXECUTE_PROCESS (COMMAND ${SAC2C_T} -M ${file_name}
                     OUTPUT_VARIABLE dep_str OUTPUT_STRIP_TRAILING_WHITESPACE)

    # XXX Currently this is correct, as sac2c always inserts '\n'.
    #     However, in case we ever support Windows, we might rethink this.
    STRING (REPLACE "\n" ";" dep_list "${dep_str}")

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
    FOREACH (dep ${dep_list})
        # If dependency is a Mod or a Tree file
        STRING (REGEX MATCH "^lib(.+)(Mod|Tree)${TREE_DLLEXT}$" match "${dep}")
        IF (match)
            SET (n "${CMAKE_MATCH_1}")
            SET (libtype "${CMAKE_MATCH_2}")

            # Check if the same name can be found amongst the sources of the
            # current package.
            IF ("${n}.sac" IN_LIST local_file_list)
                # If so, keep it as a dependency.
                LIST (APPEND ret  "${DLL_BUILD_DIR}/${TARGET_ENV}/${SBI}/${dep}")
            ELSEIF ("${n}.xsac" IN_LIST local_file_list)
                # If so, keep it as a dependency.
                LIST (APPEND ret  "${DLL_BUILD_DIR}/${TARGET_ENV}/${SBI}/${dep}")
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
                             "to build `${file_name}' is not found!")
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

