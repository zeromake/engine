
add_rules("mode.debug", "mode.release")


add_repositories("zeromake https://github.com/zeromake/xrepo.git")

add_includedirs("..", ".", "$(buildir)/flat_generate")

set_languages("c++17")
set_rundir("$(projectdir)")

add_defines("FLUTTER_RELEASE=1")

add_requires(
    "spirv_cross",
    "shaderc",
    "spirv_tools",
    "glslang",
    "flatbuffers",
    "inja",
    "nlohmann_json",
    "abseil",
    "icu4c"
)
includes("rules/impellerc.lua")
includes("rules/flatc.lua")

target("impeller.imgui.shaders")
    set_kind("object")
    add_rules("impellerc", {
        metal = false,
        vulkan = true,
    })
    add_files("impeller/playground/imgui/*.frag")
    add_files("impeller/playground/imgui/*.vert")

target("impeller.fbs")
    set_kind("object")
    add_rules("flatc")
    add_files("impeller/shader_bundle/*.fbs")
    add_files("impeller/runtime_stage/*.fbs")
    add_files("impeller/shader_archive/*.fbs")

target("impeller.base")
    set_kind("static")
    add_files("impeller/base/*.cc|*_unittests.cc")
target("impeller.core")
    set_kind("static")
    add_files("impeller/core/*.cc|*_unittests.cc")
target("impeller.geometry")
    set_kind("static")
    add_files("impeller/geometry/*.cc|*_unittests.cc|*_benchmarks.cc")
target("impeller.runtime_stage")
    set_kind("static")
    add_packages("flatbuffers")
    add_files("impeller/runtime_stage/*.cc|*_unittests.cc|*_benchmarks.cc|runtime_stage_playground.cc")
target("impeller.tessellator")
    set_kind("static")
    add_files("impeller/tessellator/tessellator.cc")
target("impeller.aiks")
    set_kind("static")
    add_files("impeller/aiks/*.cc|*_unittests.cc|*_benchmarks.cc|aiks_playground.cc")
target("impeller.display_list")
    set_kind("static")
    add_files("impeller/display_list/*.cc|*_unittests.cc")
target("impeller.entity")
    set_kind("static")
    add_files("impeller/entity/*.cc|*_unittests.cc|entity_playground.cc")
    add_files("impeller/entity/contents/*.cc|*_unittests.cc")
    add_files("impeller/entity/contents/filters/*.cc|*_unittests.cc")
    add_files("impeller/entity/geometry/*.cc|*_unittests.cc")
target("impeller.renderer")
    set_kind("static")
    add_files("impeller/renderer/*.cc|*_unittests.cc")

target("fml")
    set_kind("static")
    add_packages("abseil", "icu4c")
    add_files("fml/*.cc|*_unittests.cc|*_unittest.cc|*_benchmark.cc")
    add_files("fml/memory/*.cc|*_unittests.cc|*_unittest.cc|*_benchmark.cc")
    add_files("fml/synchronization/*.cc|*_unittests.cc|*_unittest.cc|*_benchmark.cc")
    add_files("fml/time/*.cc|*_unittests.cc|*_unittest.cc|*_benchmark.cc")
    if is_plat("windows") then
        add_files("fml/platform/win/*.cc|*_unittests.cc")
    elseif is_plat("linux") then
        add_files("fml/platform/linux/*.cc|*_unittests.cc")
        add_files("fml/platform/posix/*.cc|*_unittests.cc")
    elseif is_plat("macosx", "iphoneos") then
        set_values("objc.build.arc", false)
        add_mxxflags("-fno-objc-arc")
        add_files("fml/platform/darwin/*.cc|*_unittests.cc")
        add_files("fml/platform/darwin/*.mm|*_unittests.mm")
        add_files("fml/platform/posix/*.cc|*_unittests.cc")
    end
    on_config(function ()
        -- mock dart_tools_api.h
        local dart_tools_api_file = "third_party/dart/runtime/include/dart_tools_api.h"
        os.mkdir(path.directory(dart_tools_api_file))
        if not os.exists(dart_tools_api_file) then
            io.writefile(dart_tools_api_file, [[
#ifndef RUNTIME_INCLUDE_DART_TOOLS_API_H_
#define RUNTIME_INCLUDE_DART_TOOLS_API_H_

typedef enum {
  Dart_Timeline_Event_Begin,          // Phase = 'B'.
  Dart_Timeline_Event_End,            // Phase = 'E'.
  Dart_Timeline_Event_Instant,        // Phase = 'i'.
  Dart_Timeline_Event_Duration,       // Phase = 'X'.
  Dart_Timeline_Event_Async_Begin,    // Phase = 'b'.
  Dart_Timeline_Event_Async_End,      // Phase = 'e'.
  Dart_Timeline_Event_Async_Instant,  // Phase = 'n'.
  Dart_Timeline_Event_Counter,        // Phase = 'C'.
  Dart_Timeline_Event_Flow_Begin,     // Phase = 's'.
  Dart_Timeline_Event_Flow_Step,      // Phase = 't'.
  Dart_Timeline_Event_Flow_End,       // Phase = 'f'.
} Dart_Timeline_Event_Type;

#endif  // RUNTIME_INCLUDE_DART_TOOLS_API_H_
]])
        end
    end)

target("impeller.compiler")
    add_files("impeller/compiler/*.cc|*_unittests.cc|*_test.cc")
    add_deps("impeller.runtime_stage", "impeller.base", "fml")
    add_packages("spirv_cross", "shaderc", "spirv_tools", "glslang", "flatbuffers", "inja", "nlohmann_json")

target("impeller.shader_archive")
    add_files("impeller/shader_archive/*.cc|*_unittests.cc")
    add_deps("impeller.base", "fml")
    add_packages("flatbuffers")

-- target("renderer/backend")
-- target("typographer")
-- target("typographer/backends/stb")

-- target("impeller")
--     add_deps(
--         "base", 
--         "geometry",
--         "tessellator",
--         "display_list",
--         "entity",
--         "aiks",
--         "renderer",
--         "typographer"
--     )