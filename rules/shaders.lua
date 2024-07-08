import("lib.detect.find_tool")

local function generate_args(shader_path, opt)
    local generated_dir = opt.dir
    if opt.subdir and opt.use_subdir then
        generated_dir = generated_dir .. "/" .. opt.subdir
    end
    local args = {}
    local shader_lib_dir = "impeller/compiler/shader_lib"
    table.insert(args, "--include="..shader_lib_dir)
    if opt.gles_language_version then
        table.insert(args, "--gles-language-version=" .. opt.gles_language_version)
    end
    if opt.metal_version then
        table.insert(args, "--metal-version=" .. opt.metal_version)
    end
    if opt.use_half_textures then
        table.insert(args, "--use-half-textures")
    end
    local source_file_part = path.filename(shader_path)
    local sl_output = path.join(generated_dir, source_file_part..opt.sl_file_extension)
    local reflection_json_intermediate = path.join(generated_dir, source_file_part..".json")
    local reflection_header_intermediate = path.join(generated_dir, source_file_part..".h")
    local reflection_cc_intermediate = path.join(generated_dir, source_file_part..".cc")
    local spirv_intermediate = path.join(generated_dir, source_file_part..".spirv")
    local depfile_path =  path.join(generated_dir, source_file_part..".d")
    local source_dir = path.directory(shader_path)

    table.insert(args, "--input="..shader_path)
    table.insert(args, "--include="..source_dir)
    table.insert(args, "--depfile="..depfile_path)

    table.insert(args, "--sl="..sl_output)
    table.insert(args, "--spirv="..spirv_intermediate)
    table.insert(args, "--reflection-json="..reflection_json_intermediate)
    table.insert(args, "--reflection-header="..reflection_header_intermediate)
    table.insert(args, "--reflection-cc="..reflection_cc_intermediate)
    for _, define in ipairs(opt.defines) do
        table.insert(args, "--define="..define)
    end
    for _, item in ipairs(opt.args) do
        table.insert(args, item)
    end
    if not os.exists(generated_dir) then
        opt.batchcmds:mkdir(generated_dir)
    end
    return args, sl_output
end

local function generate_vulkan(impellerc, shaders, opt)
    local options = table.join({
        args = {},
        defines = {},
    }, opt)
    options.sl_file_extension = ".vkspv"
    options.subdir = "vk"
    table.insert(options.args, '--vulkan')
    table.insert(options.defines, 'IMPELLER_TARGET_VULKAN')
    if opt.metal then
        options.use_subdir = true
    end
    local sl_outputs = {}
    for _, shader in ipairs(shaders) do
        local args, sl_output = generate_args(shader, options)
        opt.batchcmds:vexecv(impellerc.program, args)
        table.insert(sl_outputs, sl_output)
    end
    local generated_dir = opt.dir
    if options.subdir then
        generated_dir = generated_dir .. "/" .. options.subdir
    end
    local shader_archive = find_tool('impeller.shader_archive', {paths=opt.targetdir, check = '--help'})
    local output_file = path.join(generated_dir, opt.name..".shar")
    local args = {'--output='..output_file}
    for _, sl_output in ipairs(sl_outputs) do
        table.insert(args, '--input='..sl_output)
    end
    opt.batchcmds:vexecv(shader_archive.program, args)
    -- xxd 生成
    local python = find_tool('python3', {check = '-V'})
    local embed_basename = opt.name.."_shaders_vk"
    local embed_hdr = embed_basename..".h"
    local embed_cc = embed_basename..".cc"

    local embed_args = {
        "impeller/tools/xxd.py",
        "--symbol-name",
        embed_basename,
        "--output-header",
        path.join(generated_dir, embed_hdr),
        "--output-source",
        path.join(generated_dir, embed_cc),
        "--source",
        output_file,
    }
    opt.batchcmds:vexecv(python.program, embed_args)
end


local function generate_metal(impellerc, shaders, opt)
    local options = table.join({
        args = {},
        defines = {},
    }, opt)
    options.sl_file_extension = ".metal"
    options.subdir = "mtl"
    local metal_version = "2.1"
    if is_plat("macosx") then
        options.metal_version = "2.1"
        table.insert(options.args, '--metal-desktop')
        table.insert(options.defines, 'IMPELLER_TARGET_METAL_DESKTOP')
    else
        options.metal_version = "2.4"
        metal_version = "2.4"
        table.insert(options.args, '--metal-ios')
        table.insert(options.defines, 'IMPELLER_TARGET_METAL_IOS')
    end
    table.insert(options.defines, 'IMPELLER_TARGET_METAL')
    local sl_outputs = {}
    for _, shader in ipairs(shaders) do
        local args, sl_output = generate_args(shader, options)
        opt.batchcmds:vexecv(impellerc.program, args)
        table.insert(sl_outputs, sl_output)
    end
    local generated_dir = opt.dir
    if options.subdir then
        generated_dir = generated_dir .. "/" .. options.subdir
    end
    local python = find_tool('python3', {check = '-V'})
    local metal_output = path.join(generated_dir, opt.name..".metallib")
    local metal_depfile = path.join(generated_dir, opt.name..".depfile")
    local metal_args = {
        "impeller/tools/metal_library.py",
        "--output",
        metal_output,
        "--depfile",
        metal_depfile,
        "--metal-version="..metal_version,
    }
    if is_plat("macosx") then
        table.insert(metal_args, "--platform=mac")
    else
        table.insert(metal_args, "--platform=ios")
    end
    for _, sl_output in ipairs(sl_outputs) do
        table.insert(metal_args, '--source='..sl_output)
    end
    opt.batchcmds:vexecv(python.program, metal_args)
    local embed_basename = opt.name.."_shaders"
    local embed_hdr = embed_basename..".h"
    local embed_cc = embed_basename..".cc"

    local embed_args = {
        "impeller/tools/xxd.py",
        "--symbol-name",
        embed_basename,
        "--output-header",
        path.join(generated_dir, embed_hdr),
        "--output-source",
        path.join(generated_dir, embed_cc),
        "--source",
        metal_output,
    }
    opt.batchcmds:vexecv(python.program, embed_args)
end


local function generate_gles(impellerc, shaders, opt)
    local options = table.join({
        args = {},
        defines = {},
    }, opt)
    options.subdir = "gles"
    options.sl_file_extension = ".gles"
    options.gles_language_version = 460
    table.insert(options.args, '--opengl-es')
    table.insert(options.defines, 'IMPELLER_TARGET_OPENGLES')
    if opt.metal or opt.vulkan then
        options.use_subdir = true
    end
    local sl_outputs = {}
    for _, shader in ipairs(shaders) do
        local args, sl_output = generate_args(shader, options)
        opt.batchcmds:vexecv(impellerc.program, args)
        table.insert(sl_outputs, sl_output)
    end
    local generated_dir = opt.dir
    if options.subdir then
        generated_dir = generated_dir .. "/" .. options.subdir
    end
    local shader_archive = find_tool('impeller.shader_archive', {paths=opt.targetdir, check = '--help'})
    local output_file = path.join(generated_dir, opt.name..".shar")
    local args = {'--output='..output_file}
    for _, sl_output in ipairs(sl_outputs) do
        table.insert(args, '--input='..sl_output)
    end
    opt.batchcmds:vexecv(shader_archive.program, args)
    -- xxd 生成
    local python = find_tool('python3', {check = '-V'})
    local embed_basename = opt.name.."_shaders_gles"
    local embed_hdr = embed_basename..".h"
    local embed_cc = embed_basename..".cc"

    local embed_args = {
        "impeller/tools/xxd.py",
        "--symbol-name",
        embed_basename,
        "--output-header",
        path.join(generated_dir, embed_hdr),
        "--output-source",
        path.join(generated_dir, embed_cc),
        "--source",
        output_file,
    }
    opt.batchcmds:vexecv(python.program, embed_args)
end

function main(shaders, opt)
    local impellerc = find_tool('impeller.compiler', {paths=opt.targetdir, check = '--help'})
    if opt.metal then
        generate_metal(impellerc, shaders, opt)
    end
    if opt.vulkan then
        generate_vulkan(impellerc, shaders, opt)
    end
    if opt.gles then
        generate_gles(impellerc, shaders, opt)
    end
end
