# Building PyBind11 bindings with CMake (see https://pybind11.readthedocs.io/en/latest/compiling.html#building-with-cmake)

find_package(PythonLibs 3 REQUIRED)
MESSAGE( " *** PYTHON_INCLUDE_DIRS : " ${PYTHON_INCLUDE_DIRS} )
MESSAGE( " *** PYTHON_LIBRARIES : " ${PYTHON_LIBRARIES} )

include_directories(${PYTHON_INCLUDE_DIRS})

set(popl_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/3rd/popl/include)
set(BINDINGS_LIB_NAME ${PROJECT_NAME}_python)

SET(SOURCES
  bindings.cc
  my_rgbd_slam.cc
  ${PROJECT_SOURCE_DIR}/example/util/tum_rgbd_util.cc
)

add_subdirectory(pybind11)

# There are two options here: SHARED and MODULE. 
# I don't know the difference, but SHARED let's the library be used in a brand new environment without the installed dependencies.
pybind11_add_module(${BINDINGS_LIB_NAME} MODULE ${SOURCES})

# Link OpenVSLAM
target_link_libraries(${BINDINGS_LIB_NAME}
						PRIVATE
						${PROJECT_NAME}
						${PYTHON_LIBRARIES}
						opencv_imgcodecs
                        opencv_videoio)

# include popl and spdlog headers
target_include_directories(${BINDINGS_LIB_NAME}
                            PRIVATE
                            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/3rd/popl/include>
                            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/3rd/spdlog/include>)