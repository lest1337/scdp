cmake_minimum_required(VERSION 3.10.0)
project(scdp VERSION 0.1.0 LANGUAGES C)

file(GLOB_RECURSE SOURCES "src/*.c")

add_executable(scdp ${SOURCES})