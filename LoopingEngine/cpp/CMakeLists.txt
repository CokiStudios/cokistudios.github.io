cmake_minimum_required(VERSION 3.14)
project(LoopingEngine VERSION 2.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

add_executable(looping main.cpp)

set_target_properties(looping PROPERTIES
    OUTPUT_NAME "looping"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../bin"
)
