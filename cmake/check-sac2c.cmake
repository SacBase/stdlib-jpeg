IF (NOT SAC2C_EXEC)
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

