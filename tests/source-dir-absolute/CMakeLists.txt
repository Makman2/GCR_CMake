cmake_minimum_required(VERSION 3.0)

get_filename_component(ProjectFolder ${CMAKE_CURRENT_LIST_DIR} NAME)
string(REPLACE " " "_" ProjectFolder ${ProjectFolder})
project("GCR_CMake-testcase-${ProjectFolder}")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../macros)

include(GlibCompileResourcesSupport)

# We use SOURCE_DIR below relative to "assets", so the asset paths should work relative to this directory.
list(APPEND RESOURCES resource.txt)

compile_gresources(RESOURCE_OUT
                   XML_OUT
                   TYPE BUNDLE
                   SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/assets
                   RESOURCES ${RESOURCES})

add_custom_target(resources
                  ALL
                  DEPENDS ${RESOURCE_OUT})
