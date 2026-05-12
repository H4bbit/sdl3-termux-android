cmake_minimum_required(VERSION 3.12.0)

project(SDL3_Termux_Android C CXX)

set(CMAKE_CXX_STANDARD 17)

set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)

add_subdirectory(vendor/SDL)

if(ANDROID)
    add_library(sdl-android-app SHARED
        src/main.c
    )
else()
    add_executable(sdl-android-app
        src/main.c
    )
endif()

target_link_libraries(sdl-android-app PRIVATE
    SDL3::SDL3
    c++
)

set_property(TARGET sdl-android-app PROPERTY WIN32_EXECUTABLE TRUE)

if(EMSCRIPTEN)
    set_property(TARGET sdl-android-app PROPERTY SUFFIX ".html")
endif()
