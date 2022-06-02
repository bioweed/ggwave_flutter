# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(ggwave_flutter_library VERSION 0.0.1 LANGUAGES C)

add_library(ggwave_flutter SHARED
  "ggwave_flutter.c"
)

set_target_properties(ggwave_flutter PROPERTIES
  PUBLIC_HEADER ggwave_flutter.h
  OUTPUT_NAME "ggwave_flutter"
)

target_compile_definitions(ggwave_flutter PUBLIC DART_SHARED_LIB)
