cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "tomeui_pointer_lock")
project(${PROJECT_NAME} LANGUAGES C CXX)

# Used by the Flutter tooling to find the plugin library; must not change.
set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND_CLIENT REQUIRED IMPORTED_TARGET wayland-client)
pkg_check_modules(WAYLAND_PROTOCOLS REQUIRED wayland-protocols>=1.14)
pkg_get_variable(WAYLAND_PROTOCOLS_DIR wayland-protocols pkgdatadir)
pkg_get_variable(WAYLAND_SCANNER wayland-scanner wayland_scanner)
if(NOT WAYLAND_SCANNER)
  find_program(WAYLAND_SCANNER wayland-scanner REQUIRED)
endif()

# Generate the client bindings for a protocol XML into the build tree.
set(PROTOCOL_DIR "${CMAKE_CURRENT_BINARY_DIR}/protocols")
file(MAKE_DIRECTORY "${PROTOCOL_DIR}")
function(wayland_protocol name xml)
  set(header "${PROTOCOL_DIR}/${name}-client-protocol.h")
  set(source "${PROTOCOL_DIR}/${name}-protocol.c")
  add_custom_command(
    OUTPUT "${header}"
    COMMAND "${WAYLAND_SCANNER}" client-header "${xml}" "${header}"
    DEPENDS "${xml}" VERBATIM)
  add_custom_command(
    OUTPUT "${source}"
    COMMAND "${WAYLAND_SCANNER}" private-code "${xml}" "${source}"
    DEPENDS "${xml}" VERBATIM)
  set(PROTOCOL_SOURCES ${PROTOCOL_SOURCES} "${header}" "${source}" PARENT_SCOPE)
endfunction()

wayland_protocol(pointer-constraints-unstable-v1
  "${WAYLAND_PROTOCOLS_DIR}/unstable/pointer-constraints/pointer-constraints-unstable-v1.xml")
wayland_protocol(relative-pointer-unstable-v1
  "${WAYLAND_PROTOCOLS_DIR}/unstable/relative-pointer/relative-pointer-unstable-v1.xml")

list(APPEND PLUGIN_SOURCES
  "tomeui_pointer_lock_plugin.cc"
  ${PROTOCOL_SOURCES}
)

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE "${PROTOCOL_DIR}")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::WAYLAND_CLIENT)

set(tomeui_pointer_lock_bundled_libraries
  ""
  PARENT_SCOPE
)
