include(GenerateExportHeader)


add_library(commonLib commonLib.cpp)

add_library(windengine::commonLib ALIAS commonLib)

target_link_libraries(commonLib PRIVATE windengine_options windengine_warnings)

target_include_directories(commonLib ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/client>
                                                                  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/client>)

target_compile_features(commonLib PUBLIC cxx_std_20)

set_target_properties(
    commonLib
  PROPERTIES VERSION ${PROJECT_VERSION}
             CXX_VISIBILITY_PRESET hidden
             VISIBILITY_INLINES_HIDDEN YES)

generate_export_header(commonLib EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/client/commonLib/commonLib_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(commonLib PUBLIC COMMON_LIBRARY_STATIC_DEFINE)
endif()