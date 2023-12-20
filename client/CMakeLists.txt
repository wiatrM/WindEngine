add_subdirectory(core)
add_subdirectory(commonLib)

add_executable(intro main.cpp)

target_link_libraries(
  intro
  PRIVATE windengine::windengine_options
          windengine::windengine_warnings)

target_link_system_libraries(
  intro
  PRIVATE
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          sfml-system sfml-network sfml-graphics sfml-window)

target_include_directories(intro PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")