include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(windengine_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(windengine_setup_options)
  option(windengine_ENABLE_HARDENING "Enable hardening" ON)
  option(windengine_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    windengine_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    windengine_ENABLE_HARDENING
    OFF)

  windengine_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR windengine_PACKAGING_MAINTAINER_MODE)
    option(windengine_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(windengine_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(windengine_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(windengine_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(windengine_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(windengine_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(windengine_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(windengine_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(windengine_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(windengine_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(windengine_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(windengine_ENABLE_PCH "Enable precompiled headers" OFF)
    option(windengine_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(windengine_ENABLE_IPO "Enable IPO/LTO" ON)
    option(windengine_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(windengine_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(windengine_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(windengine_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(windengine_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(windengine_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(windengine_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(windengine_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(windengine_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(windengine_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(windengine_ENABLE_PCH "Enable precompiled headers" OFF)
    option(windengine_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      windengine_ENABLE_IPO
      windengine_WARNINGS_AS_ERRORS
      windengine_ENABLE_USER_LINKER
      windengine_ENABLE_SANITIZER_ADDRESS
      windengine_ENABLE_SANITIZER_LEAK
      windengine_ENABLE_SANITIZER_UNDEFINED
      windengine_ENABLE_SANITIZER_THREAD
      windengine_ENABLE_SANITIZER_MEMORY
      windengine_ENABLE_UNITY_BUILD
      windengine_ENABLE_CLANG_TIDY
      windengine_ENABLE_CPPCHECK
      windengine_ENABLE_COVERAGE
      windengine_ENABLE_PCH
      windengine_ENABLE_CACHE)
  endif()

  windengine_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (windengine_ENABLE_SANITIZER_ADDRESS OR windengine_ENABLE_SANITIZER_THREAD OR windengine_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(windengine_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(windengine_global_options)
  if(windengine_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    windengine_enable_ipo()
  endif()

  windengine_supports_sanitizers()

  if(windengine_ENABLE_HARDENING AND windengine_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR windengine_ENABLE_SANITIZER_UNDEFINED
       OR windengine_ENABLE_SANITIZER_ADDRESS
       OR windengine_ENABLE_SANITIZER_THREAD
       OR windengine_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${windengine_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${windengine_ENABLE_SANITIZER_UNDEFINED}")
    windengine_enable_hardening(windengine_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(windengine_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(windengine_warnings INTERFACE)
  add_library(windengine_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  windengine_set_project_warnings(
    windengine_warnings
    ${windengine_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(windengine_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(windengine_options)
  endif()

  include(cmake/Sanitizers.cmake)
  windengine_enable_sanitizers(
    windengine_options
    ${windengine_ENABLE_SANITIZER_ADDRESS}
    ${windengine_ENABLE_SANITIZER_LEAK}
    ${windengine_ENABLE_SANITIZER_UNDEFINED}
    ${windengine_ENABLE_SANITIZER_THREAD}
    ${windengine_ENABLE_SANITIZER_MEMORY})

  set_target_properties(windengine_options PROPERTIES UNITY_BUILD ${windengine_ENABLE_UNITY_BUILD})

  if(windengine_ENABLE_PCH)
    target_precompile_headers(
      windengine_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(windengine_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    windengine_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(windengine_ENABLE_CLANG_TIDY)
    windengine_enable_clang_tidy(windengine_options ${windengine_WARNINGS_AS_ERRORS})
  endif()

  if(windengine_ENABLE_CPPCHECK)
    windengine_enable_cppcheck(${windengine_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(windengine_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    windengine_enable_coverage(windengine_options)
  endif()

  if(windengine_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(windengine_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(windengine_ENABLE_HARDENING AND NOT windengine_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR windengine_ENABLE_SANITIZER_UNDEFINED
       OR windengine_ENABLE_SANITIZER_ADDRESS
       OR windengine_ENABLE_SANITIZER_THREAD
       OR windengine_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    windengine_enable_hardening(windengine_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
