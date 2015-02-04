include(CMakeParseArguments)

# Finds the glib-compile-resources executable.
find_program(GLIB_COMPILE_RESOURCES_EXECUTABLE glib-compile-resources)
mark_as_advanced(GLIB_COMPILE_RESOURCES_EXECUTABLE)

# Compiles a gresource resource file from given resource files. Automatically
# creates the XML controlling file.
# The type of resource to generate (header, c-file or bundle) is automatically
# determined from TARGET file ending, if no TYPE is explicitly specified.
# The output file is stored in the provided variable "output".
# If you want to use preprocessing, you need to manually check the existence
# of the tools you use. This function doesn't check this for you, it just
# generates the XML file. glib-compile-resources will then throw a
# warning/error.
function(COMPILE_GRESOURCES output)
    # Available options:
    # COMPRESS_ALL, NO_COMPRESS_ALL       Overrides the COMPRESS flag in all
    #                                     registered resources.
    # STRIPBLANKS_ALL, NO_STRIPBLANKS_ALL Overrides the STRIPBLANKS flag in all
    #                                     registered resources.
    # TOPIXDATA_ALL, NO_TOPIXDATA_ALL     Overrides the TOPIXDATA flag in all
    #                                     registered resources.
    set(CG_OPTIONS COMPRESS_ALL NO_COMPRESS_ALL
                   STRIPBLANKS_ALL NO_STRIPBLANKS_ALL
                   TOPIXDATA_ALL NO_TOPIXDATA_ALL)

    # Available one value options:
    # TYPE       Type of resource to create. Valid options are:
    #            EMBED_C: A C-file that can be compiled with your project.
    #            EMBED_H: A header that can be included into your project.
    #            BUNDLE:  Generates a resource bundle file that can be loaded
    #                     at runtime.
    #            AUTO:    Determine from target file ending. Need to specify
    #                     target argument.
    # PREFIX     Overrides the resource prefix that is prepended to each
    #            relative file name in registered resources.
    # SOURCE_DIR Overrides the resources base directory to search for resources.
    #            Normally this is set to the source directory with that CMake
    #            was invoked (CMAKE_SOURCE_DIR).
    # TARGET     Overrides the name of the output file/-s. Normally the output
    #            names from glib-compile-resources tool is taken.
    set(CG_ONEVALUEARGS TYPE PREFIX SOURCE_DIR TARGET)

    # Available multi-value options:
    # RESOURCES The list of resource files. Whether absolute or relative path is
    #           equal, absolute paths are stripped down to relative ones. If the
    #           absolute path is not inside the given base directory SOURCE_DIR
    #           or CMAKE_SOURCE_DIR (if SOURCE_DIR is not overriden), this
    #           function aborts.
    # OPTIONS   Extra command line options passed to glib-compile-resources.
    set(CG_MULTIVALUEARGS RESOURCES OPTIONS)

    # Parse the arguments.
    cmake_parse_arguments(CG_ARG
                          "${CG_OPTIONS}"
                          "${CG_ONEVALUEARGS}"
                          "${CG_MULTIVALUEARGS}"
                          "${ARGN}")

    # Variable to store the double-quote (") string. Since escaping
    # double-quotes in strings is not possible we need a helper variable that
    # does this job for us.
    set(Q \")

    # Check invocation validity with the <prefix>_UNPARSED_ARGUMENTS variable.
    # If other not recognized parameters were passed, throw error.
    if (CG_ARG_UNPARSED_ARGUMENTS)
        set(CG_WARNMSG
            "Invocation of COMPILE_GRESOURCES with unrecognized parameters.")
        set(CG_WARNMSG
            "${CG_WARNMSG} Parameters are: ${CG_ARG_UNPARSED_ARGUMENTS}.")
        message(WARNING ${CG_WARNMSG})
    endif()

    # Check invocation validity depending on generation mode (EMBED_C, EMBED_H
    # or BUNDLE).
    if ("${CG_ARG_TYPE}" STREQUAL "EMBED_C")
        # EMBED_C mode, output compilable C-file.
        set(CG_GENERATE_COMMAND_LINE "--generate-source")
        set(CG_TARGET_FILE_ENDING "c")
    elseif ("${CG_ARG_TYPE}" STREQUAL "EMBED_H")
        # EMBED_H mode, output includable header file.
        set(CG_GENERATE_COMMAND_LINE "--generate-header")
        set(CG_TARGET_FILE_ENDING "h")
    elseif ("${CG_ARG_TYPE}" STREQUAL "BUNDLE")
        # BUNDLE mode, output resource bundle. Don't do anything since
        # glib-compile-resources outputs a bundle when not specifying
        # something else.
        set(CG_TARGET_FILE_ENDING "gresource")
    else()
        # Everything else is AUTO mode, determine from target file ending.
        if (CG_ARG_TARGET)
            set(CG_GENERATE_COMMAND_LINE "--generate")
        else()
            set(CG_ERRMSG
                "AUTO mode given, but no target specified. Can't determine")
            set(CG_ERRMSG
                "${CG_ERRMSG} output type. In function COMPILE_GRESOURCES.")
            message(FATAL_ERROR ${CG_ERRMSG})
        endif()
    endif()

    # Check flag validity.
    if (CG_ARG_COMPRESS_ALL AND CG_ARG_NO_COMPRESS_ALL)
        set(CG_ERRMSG
            "COMPRESS_ALL and NO_COMPRESS_ALL simultaneously set. In function")
        set(CG_ERRMSG
            "${CG_ERRMSG} COMPILE_GRESOURCES.")
        message(FATAL_ERROR ${CG_ERRMSG})
    endif()
    if (CG_ARG_STRIPBLANKS_ALL AND CG_ARG_NO_STRIPBLANKS_ALL)
        set(CG_ERRMSG
            "STRIPBLANKS_ALL and NO_STRIPBLANKS_ALL simultaneously set. In")
        set(CG_ERRMSG
            "${CG_ERRMSG} function COMPILE_GRESOURCES.")
        message(FATAL_ERROR ${CG_ERRMSG})
    endif()
    if (CG_ARG_TOPIXDATA_ALL AND CG_ARG_NO_TOPIXDATA_ALL)
        set(CG_ERRMSG
            "TOPIXDATA_ALL and NO_TOPIXDATA_ALL simultaneously set. In")
        set(CG_ERRMSG
            "${CG_ERRMSG} function COMPILE_GRESOURCES.")
        message(FATAL_ERROR ${CG_ERRMSG})
    endif()

    # Check if there are any resources.
    if (NOT CG_ARG_RESOURCES)
        set(CG_ERRMSG
            "No resource files to process. In function COMPILE_GRESOURCES.")
        message(FATAL_ERROR ${CG_ERRMSG})
    endif()

    # Process resources and generate XML file.
    # Begin with the XML header and header nodes.
    set(CG_XML_FILE "<?xml version=${Q}1.0${Q} encoding=${Q}UTF-8${Q}?>")
    set(CG_XML_FILE "${CG_XML_FILE}<gresources><gresource prefix=${Q}")

    # Set the prefix for the resources. Depending on the user-override we choose
    # the standard prefix "/" or the override.
    if (CG_ARG_PREFIX)
        set(CG_XML_FILE "${CG_XML_FILE}${CG_ARG_PREFIX}")
    else()
        set(CG_XML_FILE "${CG_XML_FILE}/")
    endif()

    set(CG_XML_FILE "${CG_XML_FILE}${Q}>")

    # Process each resource.
    foreach(res ${CG_ARG_RESOURCES})
        if ("${res}" STREQUAL "COMPRESS")
            set(CG_COMPRESSION_FLAG ON)
        elseif ("${res}" STREQUAL "STRIPBLANKS")
            set(CG_STRIPBLANKS_FLAG ON)
        elseif ("${res}" STREQUAL "TOPIXDATA")
            set(CG_TOPIXDATA_FLAG ON)
        else()
            # The file name.
            set(CG_RESOURCE_PATH "${res}")

            # Append to real resource file dependency list.
            list(APPEND CG_RESOURCES_DEPENDENCIES ${CG_RESOURCE_PATH})

            # Assemble <file> node.
            set(CG_RES_LINE "<file")
            if ((CG_ARG_COMPRESS_ALL OR CG_COMPRESSION_FLAG) AND NOT
                    CG_ARG_NO_COMPRESS_ALL)
                set(CG_RES_LINE "${CG_RES_LINE} compressed=${Q}true${Q}")
            endif()

            # Check preprocess flag validity.
            if ((CG_ARG_STRIPBLANKS_ALL OR CG_STRIPBLANKS_FLAG) AND
                    (CG_ARG_TOPIXDATA_ALL OR CG_TOPIXDATA_FLAG))
                set(CG_ERRMSG
                    "Resource preprocessing option conflict. Tried to specify")
                set(CG_ERRMSG
                    "${CG_ERRMSG} both, STRIPBLANKS and TOPIXDATA. In resource")
                set(CG_ERRMSG
                    "${CG_ERRMSG} ${CG_RESOURCE_PATH} in function")
                set(CG_ERRMSG
                    "${CG_ERRMSG} COMPILE_GRESOURCES.")
                message(FATAL_ERROR ${CG_ERRMSG})
            endif()

            if ((CG_ARG_STRIPBLANKS_ALL OR CG_STRIPBLANKS_FLAG) AND NOT
                    CG_ARG_NO_STRIPBLANKS_ALL)
                set(CG_RES_LINE "${CG_RES_LINE} preprocess=")
                set(CG_RES_LINE "${CG_RES_LINE}${Q}xml-stripblanks${Q}")
            elseif((CG_ARG_TOPIXDATA_ALL OR CG_TOPIXDATA_FLAG) AND NOT
                       CG_ARG_NO_TOPIXDATA_ALL)
                set(CG_RES_LINE "${CG_RES_LINE} preprocess=${Q}to-pixdata${Q}")
            endif()

            set(CG_RES_LINE "${CG_RES_LINE}>${CG_RESOURCE_PATH}</file>")

            # Append to file string.
            set(CG_XML_FILE
                "${CG_XML_FILE}${CG_RES_LINE}")

            # Unset variables.
            unset(CG_COMPRESSION_FLAG)
            unset(CG_STRIPBLANKS_FLAG)
            unset(CG_TOPIXDATA_FLAG)
        endif()

    endforeach(res)

    # Append closing nodes.
    set(CG_XML_FILE "${CG_XML_FILE}</gresource></gresources>")

    # Use "file" function to generate XML controlling file.
    set(CG_XML_FILE_NAME ".gresource.xml")
    set(CG_XML_FILE_PATH "${CMAKE_BINARY_DIR}/${CG_XML_FILE_NAME}")
    message(STATUS "Generating GResource XML file (${CG_XML_FILE_NAME}).")
    file(WRITE ${CG_XML_FILE_PATH} ${CG_XML_FILE})

    # Create target manually if not set (to make sure glib-compile-resources
    # doesn't change behaviour with it's naming standards).
    if (NOT CG_ARG_TARGET)
        set(CG_ARG_TARGET "${CMAKE_BINARY_DIR}/resources")
        set(CG_ARG_TARGET "${CG_ARG_TARGET}.${CG_TARGET_FILE_ENDING}")
    endif()

    # Create source directory automatically if not set.
    if (NOT CG_ARG_SOURCE_DIR)
        set(CG_ARG_SOURCE_DIR "${CMAKE_SOURCE_DIR}")
    endif()

    # Add compilation target for resources.
    add_custom_command(OUTPUT ${CG_ARG_TARGET}
                       COMMAND ${GLIB_COMPILE_RESOURCES_EXECUTABLE}
                       ARGS
                           ${OPTIONS}
                           "--target=${Q}${CG_ARG_TARGET}${Q}"
                           "--sourcedir=${Q}${CG_ARG_SOURCE_DIR}${Q}"
                           ${CG_GENERATE_COMMAND_LINE}
                           ${CG_XML_FILE_PATH}
                       MAIN_DEPENDENCY ${CG_XML_FILE_PATH}
                       DEPENDS ${CG_RESOURCES_DEPENDENCIES}
                       WORKING_DIRECTORY ${CMAKE_BUILD_DIR})

    # Set output to parent scope.
    set(${output} ${CG_ARG_TARGET} PARENT_SCOPE)

endfunction(COMPILE_GRESOURCES)
