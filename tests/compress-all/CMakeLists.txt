cmake_minimum_required(VERSION 3.0)

get_filename_component(ProjectFolder ${CMAKE_CURRENT_LIST_DIR} NAME)
string(REPLACE " " "_" ProjectFolder ${ProjectFolder})
project("GCR_CMake-testcase-${ProjectFolder}")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../macros)

include(GlibCompileResourcesSupport)

list(APPEND RESOURCES assets/resource1.txt assets/resource2.txt)

compile_gresources(RESOURCE_OUT
                   XML_OUT
                   TYPE BUNDLE
                   RESOURCES ${RESOURCES}
                   COMPRESS_ALL)

add_custom_target(resources
                  ALL
                  DEPENDS ${RESOURCE_OUT})
