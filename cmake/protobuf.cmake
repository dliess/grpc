# Copyright 2017 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if(gRPC_PROTOBUF_PROVIDER STREQUAL "module")
  # Building the protobuf tests require gmock what is not part of a standard protobuf checkout.
  # Disable them unless they are explicitly requested from the cmake command line (when we assume
  # gmock is downloaded to the right location inside protobuf).
  if(NOT protobuf_BUILD_TESTS)
    set(protobuf_BUILD_TESTS OFF CACHE BOOL "Build protobuf tests")
  endif()
  # Disable building protobuf with zlib. Building protobuf with zlib breaks
  # the build if zlib is not installed on the system.
  if(NOT protobuf_WITH_ZLIB)
    set(protobuf_WITH_ZLIB OFF CACHE BOOL "Build protobuf with zlib.")
  endif()
  if(NOT PROTOBUF_ROOT_DIR)
    set(PROTOBUF_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf)
  endif()

  if(EXISTS "${PROTOBUF_ROOT_DIR}/cmake/CMakeLists.txt")
    set(protobuf_MSVC_STATIC_RUNTIME OFF CACHE BOOL "Link static runtime libraries")
    add_subdirectory(${PROTOBUF_ROOT_DIR}/cmake third_party/protobuf)
    if(TARGET ${_gRPC_PROTOBUF_LIBRARY_NAME})
      set(_gRPC_PROTOBUF_LIBRARIES ${_gRPC_PROTOBUF_LIBRARY_NAME})
    endif()
    if(TARGET libprotoc)
      set(_gRPC_PROTOBUF_PROTOC_LIBRARIES libprotoc)
    endif()
    if(TARGET protoc)
      set(_gRPC_PROTOBUF_PROTOC protoc)
      if(CMAKE_CROSSCOMPILING)
        find_program(_gRPC_PROTOBUF_PROTOC_EXECUTABLE protoc)
      else()
        set(_gRPC_PROTOBUF_PROTOC_EXECUTABLE $<TARGET_FILE:protoc>)
      endif()
    endif()
    # For well-known .proto files distributed with protobuf
    set(_gRPC_PROTOBUF_WELLKNOWN_INCLUDE_DIR "${PROTOBUF_ROOT_DIR}/src")
  else()
    message(WARNING "gRPC_PROTOBUF_PROVIDER is \"module\" but PROTOBUF_ROOT_DIR is wrong")
  endif()
  if(gRPC_INSTALL AND NOT _gRPC_INSTALL_SUPPORTED_FROM_MODULE)
    message(WARNING "gRPC_INSTALL will be forced to FALSE because gRPC_PROTOBUF_PROVIDER is \"module\" and CMake version (${CMAKE_VERSION}) is less than 3.13.")
    set(gRPC_INSTALL FALSE)
  endif()
elseif(gRPC_PROTOBUF_PROVIDER STREQUAL "package")
  find_package(Protobuf REQUIRED ${gRPC_PROTOBUF_PACKAGE_TYPE})

  # {Protobuf,PROTOBUF}_FOUND is defined based on find_package type ("MODULE" vs "CONFIG").
  # For "MODULE", the case has also changed between cmake 3.5 and 3.6.
  # We use the legacy uppercase version for *_LIBRARIES AND *_INCLUDE_DIRS variables
  # as newer cmake versions provide them too for backward compatibility.
  if(Protobuf_FOUND OR PROTOBUF_FOUND)
    message(INFO "----------------------- HERE1 ----------------------")
    if(CMAKE_CROSSCOMPILING)
      message(INFO "----------------------- CMAKE_CROSSCOMPILING ---------------------")
    else()
      message(INFO "----------------------- NOT CMAKE_CROSSCOMPILING ---------------------")
    endif()

    if(TARGET protobuf::${_gRPC_PROTOBUF_LIBRARY_NAME})
      message(INFO "----------------------- HERE2 ${_gRPC_PROTOBUF_LIBRARY_NAME} ----------------------")
      set(_gRPC_PROTOBUF_LIBRARIES protobuf::${_gRPC_PROTOBUF_LIBRARY_NAME})
    else()
      message(INFO "----------------------- HERE3 ----------------------")
      set(_gRPC_PROTOBUF_LIBRARIES ${PROTOBUF_LIBRARIES})
    endif()


    if(TARGET protobuf::libprotoc)
      message(INFO "----------------------- HERE4 ----------------------")
      set(_gRPC_PROTOBUF_PROTOC_LIBRARIES protobuf::libprotoc)
      # extract the include dir from target's properties
      get_target_property(_gRPC_PROTOBUF_WELLKNOWN_INCLUDE_DIR protobuf::libprotoc INTERFACE_INCLUDE_DIRECTORIES)
    else()
      message(INFO "----------------------- HERE5 ----------------------")
      set(_gRPC_PROTOBUF_PROTOC_LIBRARIES ${PROTOBUF_PROTOC_LIBRARIES})
      set(_gRPC_PROTOBUF_WELLKNOWN_INCLUDE_DIR ${PROTOBUF_INCLUDE_DIRS})
      message(INFO "_gRPC_PROTOBUF_PROTOC_LIBRARIES: ${_gRPC_PROTOBUF_PROTOC_LIBRARIES}")
      message(INFO "_gRPC_PROTOBUF_WELLKNOWN_INCLUDE_DIR: ${_gRPC_PROTOBUF_WELLKNOWN_INCLUDE_DIR}")
    endif()


    if(TARGET protobuf::protoc)
      message(INFO "----------------------- HERE6 ----------------------")
      set(_gRPC_PROTOBUF_PROTOC protobuf::protoc)
      if(CMAKE_CROSSCOMPILING)
        message(INFO "----------------------- HERE7 ----------------------")
        find_program(_gRPC_PROTOBUF_PROTOC_EXECUTABLE protoc)
      else()
        message(INFO "----------------------- HERE8 ----------------------")
        set(_gRPC_PROTOBUF_PROTOC_EXECUTABLE $<TARGET_FILE:protobuf::protoc>)
      endif()
    else()
      message(INFO "----------------------- HERE9 ----------------------")
      set(_gRPC_PROTOBUF_PROTOC ${PROTOBUF_PROTOC_EXECUTABLE})
      if(CMAKE_CROSSCOMPILING)
        message(INFO "----------------------- HERE10 ----------------------")
        find_program(_gRPC_PROTOBUF_PROTOC_EXECUTABLE protoc)
        message(INFO "----------------------- _gRPC_PROTOBUF_PROTOC_EXECUTABLE: ${_gRPC_PROTOBUF_PROTOC_EXECUTABLE} ----------------------")
      else()
        message(INFO "----------------------- HERE11 ----------------------")
        set(_gRPC_PROTOBUF_PROTOC_EXECUTABLE ${PROTOBUF_PROTOC_EXECUTABLE})
      endif()
    endif()
    set(_gRPC_FIND_PROTOBUF "if(NOT Protobuf_FOUND AND NOT PROTOBUF_FOUND)\n  find_package(Protobuf ${gRPC_PROTOBUF_PACKAGE_TYPE})\nendif()")
  endif()
endif()
