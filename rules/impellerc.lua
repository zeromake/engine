rule("impellerc")
    set_extensions(".frag", ".vert", ".comp")
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("lib.detect.find_tool")
        local enableOptions = {}
        enableOptions.metal = target:extraconf("rules", "impellerc", "metal")
        enableOptions.vulkan = target:extraconf("rules", "impellerc", "vulkan")
        enableOptions.gles = target:extraconf("rules", "impellerc", "gles")
        local targetdir = target:targetdir()
        local impellerc = find_tool('impeller.compiler', {paths=targetdir, check = '--help'})
        local sourcedir = path.directory(sourcefile)
        local sourcefilename = path.filename(sourcefile)
        local outdir = path.join(vformat("$(buildir)"), "impellerc_generate", sourcedir)
        batchcmds:mkdir(outdir)
        local spirv_intermediate_path = path.join(outdir, sourcefilename .. ".spv")
        local sl_output_path = path.join(outdir, sourcefilename)
        local argv = {
            '--input='..sourcefile,
            '--spirv='..spirv_intermediate_path,
            '--reflection-json='..path.join(outdir, sourcefilename)..'.json',
            '--reflection-header='..path.join(outdir, sourcefilename)..'.h',
            '--reflection-cc='..path.join(outdir, sourcefilename)..'.cc',
            '--include=impeller/compiler/shader_lib'
        }
        if enableOptions.vulkan then
            sl_output_path = sl_output_path .. ".vkspv"
            table.insert(argv, '--vulkan')
            table.insert(argv, '--defines=IMPELLER_TARGET_VULKAN')
        elseif enableOptions.metal then
            sl_output_path = sl_output_path .. ".metal"
            if is_plat("macosx") then
                table.insert(argv, '--metal-desktop')
                table.insert(argv, '--defines=IMPELLER_TARGET_METAL_DESKTOP')
            else
                table.insert(argv, '--metal-ios')
                table.insert(argv, '--defines=IMPELLER_TARGET_METAL_IOS')
            end
            table.insert(argv, '--defines=IMPELLER_TARGET_METAL')
        elseif enableOptions.gles then
            sl_output_path = sl_output_path .. ".gles"
            table.insert(argv, '--opengl-es')
            table.insert(argv, '--defines=IMPELLER_TARGET_OPENGLES')
        end
        table.insert(argv, '--sl='..sl_output_path)
        batchcmds:vrunv(impellerc.program, argv)
        batchcmds:show_progress(opt.progress, "${color.build.object}impellerc %s -> %s", sourcefile, sl_output_path)
        batchcmds:add_depfiles(sourcefile)
    end)
