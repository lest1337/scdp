cmake_minimum_required(VERSION 3.10.0)
project(scdp VERSION 0.1.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

file(GLOB_RECURSE SOURCES "src/*.c")

add_executable(scdp ${SOURCES})

target_compile_options(scdp PRIVATE -Wall -Wextra -pedantic)
