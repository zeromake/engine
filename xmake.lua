
add_rules("mode.debug", "mode.release")


add_repositories("zeromake https://github.com/zeromake/xrepo.git")

add_includedirs("..", ".")

set_languages("c++17")

add_requires("spirv_cross")

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

target("impeller.compiler")
    add_files("impeller/compiler/*.cc|*_unittests.cc")
    add_packages("spirv_cross")
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