### THIS FILE A IS A COPY OF THE CMAKELISTS.TXT FROM THE /EXAMPLES FOLDER

# ----- Find dependencies -----

# popl
set(popl_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/3rd/popl/include)

set(USE_STACK_TRACE_LOGGER OFF CACHE BOOL "Enable automatic stack trace logger of google-glog")
if(USE_STACK_TRACE_LOGGER)
    find_package(Glog REQUIRED)
    include_directories(${GLOG_INCLUDE_DIR})
    message(STATUS "Stack trace logger: ENABLED")
else()
    message(STATUS "Stack trace logger: DISABLED")
endif()

set(USE_GOOGLE_PERFTOOLS OFF CACHE BOOL "Enable profiler of google-perftools")
if(USE_GOOGLE_PERFTOOLS)
    find_package(Gperftools REQUIRED)
    include_directories(${GPERFTOOLS_INCLUDE_DIRS})
    message(STATUS "Google Perftools: ENABLED")
else()
    message(STATUS "Google Perftools: DISABLED")
endif()

# ----- Show dialog -----

if(USE_PANGOLIN_VIEWER)
    message(STATUS "Viewer for examples: PangolinViewer")
elseif(USE_SOCKET_PUBLISHER)
    message(STATUS "Viewer for examples: SocketPublisher")
else()
    message(STATUS "Viewer for examples: None")
endif()

# ----- Build example executables -----

# Building PyBind11 bindings with CMake (see https://pybind11.readthedocs.io/en/latest/compiling.html#building-with-cmake)
add_subdirectory(pybind11)

# There are two options here: SHARED and MODULE. 
# I don't know the difference, but SHARED let's the library be used in a brand new environment without the installed dependencies.
set(EXECUTABLE_TARGETS "")

pybind11_add_module(${PROJECT_NAME}_python SHARED bindings.cc)
list(APPEND EXECUTABLE_TARGETS ${PROJECT_NAME}_python)

add_executable(my_rgbd_slam my_rgbd_slam.cc ${PROJECT_SOURCE_DIR}/example/util/tum_rgbd_util.cc)
list(APPEND EXECUTABLE_TARGETS my_rgbd_slam)

foreach(EXECUTABLE_TARGET IN LISTS EXECUTABLE_TARGETS)
    # Set output directory for executables
    set_target_properties(${EXECUTABLE_TARGET} PROPERTIES
                          RUNTIME_OUTPUT_DIRECTORY_DEBUG "${PROJECT_BINARY_DIR}"
                          RUNTIME_OUTPUT_DIRECTORY_RELEASE "${PROJECT_BINARY_DIR}"
                          RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${PROJECT_BINARY_DIR}"
                          RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}")

    # PangolinViewer is used on a priority basis
    if(USE_PANGOLIN_VIEWER)
        # Set macro flag
        target_compile_definitions(${EXECUTABLE_TARGET} PRIVATE USE_PANGOLIN_VIEWER)
        # Link viewer
        target_link_libraries(${EXECUTABLE_TARGET} PRIVATE pangolin_viewer)
    elseif(USE_SOCKET_PUBLISHER)
        # Set macro flag
        target_compile_definitions(${EXECUTABLE_TARGET} PRIVATE USE_SOCKET_PUBLISHER)
        # Link viewer
        target_link_libraries(${EXECUTABLE_TARGET} PRIVATE socket_publisher)
    endif()

    # Setup stack trace logger
    if(USE_STACK_TRACE_LOGGER)
        target_compile_definitions(${EXECUTABLE_TARGET} PRIVATE USE_STACK_TRACE_LOGGER)
        target_link_libraries(${EXECUTABLE_TARGET} PRIVATE ${GLOG_LIBRARIES})
    endif()

    # Setup google-perftools
    if(USE_GOOGLE_PERFTOOLS)
        target_compile_definitions(${EXECUTABLE_TARGET} PRIVATE USE_GOOGLE_PERFTOOLS)
        target_link_libraries(${EXECUTABLE_TARGET} PRIVATE ${GPERFTOOLS_LIBRARIES})
    endif()

    # Link OpenVSLAM
    target_link_libraries(${EXECUTABLE_TARGET}
                          PRIVATE
                          ${PROJECT_NAME}
                          opencv_imgcodecs
                          opencv_videoio)

    # include popl and spdlog headers
    target_include_directories(${EXECUTABLE_TARGET}
                               PRIVATE
                               $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/3rd/popl/include>
                               $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/3rd/spdlog/include>)
endforeach()