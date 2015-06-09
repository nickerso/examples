cmake_minimum_required(VERSION 3.2)
# Included here from template generation
set(OPENCMISS_INSTALL_DIR @OPENCMISS_INSTALL_DIR@)
 
# Get lowercase name
#string(TOLOWER "@EXAMPLE_NAME@" EXAMPLE_NAME)
set(EXAMPLE_TARGET run)

# Get the build context from the OpenCMISS installation
if (NOT OPENCMISS_INSTALL_DIR)
    set(OPENCMISS_INSTALL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../install)
    get_filename_component(OPENCMISS_INSTALL_DIR ${OPENCMISS_INSTALL_DIR} ABSOLUTE)
endif()

# Have us look for a OpenCMISS installation directly at the given path or at the path suffixed with the current build type - ease of use.
string(TOLOWER "${CMAKE_BUILD_TYPE}" _BUILDTYPE)
find_file(HAVE_BUILDCONTEXT OpenCMISSBuildContext.cmake
    HINTS ${OPENCMISS_INSTALL_DIR} 
        ${OPENCMISS_INSTALL_DIR}/${_BUILDTYPE} 
        ${OPENCMISS_INSTALL_DIR}/release
)
unset(_BUILDTYPE)
if (NOT HAVE_BUILDCONTEXT)
    message(FATAL_ERROR "Could not find OpenCMISS. No OpenCMISSBuildContext.cmake found; OPENCMISS_INSTALL_DIR='${OPENCMISS_INSTALL_DIR}'")
endif()
include(${OPENCMISS_INSTALL_DIR}/OpenCMISSBuildContext.cmake)

project(OpenCMISSExample LANGUAGES C CXX Fortran VERSION 1.0)
SET(CMAKE_NO_SYSTEM_FROM_IMPORTED YES)

# Have CMake find the package components
list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_PREFIX_PATH}) # var defined OpenCMISSBuildContext

# Have CMake find the FindOpenCMISS file
list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH})
find_package(IRON REQUIRED)

#################### Actual example code ####################

# Get sources in /src
file(GLOB SRC src/*.f90 src/*.c ../input/*.f90)
# Add example executable
add_executable(${EXAMPLE_TARGET} ${SRC})
# Link to opencmiss - contains forward refs to all other necessary libs
target_link_libraries(${EXAMPLE_TARGET} PRIVATE iron)
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -cpp")
if (WIN32)
    target_compile_definitions(${EXAMPLE_TARGET} PRIVATE NOMPIMOD)
endif()

install(TARGETS ${EXAMPLE_TARGET} DESTINATION .)