# This file checks whether we have an operational sac2c compiler.

# SAC2C_EXEC can be passed as an argument to `cmake' call in which
# case we treat it as a path to the sac2c executable.
IF (NOT SAC2C_EXEC)
    # Try to find sac2c and fail if it is not there.
    FIND_PROGRAM (SAC2C_EXEC NAMES "sac2c")
    IF (NOT SAC2C_EXEC)
        MESSAGE (FATAL_ERROR "Could not locate the sac2c binary, exiting...")
    ENDIF ()
ENDIF ()

# Check that sac2c actually works by calling "sac2c -V"
EXECUTE_PROCESS (COMMAND ${SAC2C_EXEC} -V RESULT_VARIABLE sac2c_exec_res OUTPUT_QUIET ERROR_QUIET)
IF (NOT "${sac2c_exec_res}" STREQUAL "0")
    MESSAGE (FATAL_ERROR "Call to \"${SAC2C_EXEC} -V\" failed, something "
                         "wrong with the sac2c binary")
ENDIF ()

