rule("impellerc")
    set_extensions(".frag", ".vert", ".comp")
    on_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
        import("lib.detect.find_tool")
        local targetdir = target:targetdir()
        local sourcedir = path.directory(sourcebatch.sourcefiles[1])
        local name = target:extraconf("rules", "impellerc", "name")
        local outdir = path.join(vformat("$(buildir)"), "impellerc_generate", sourcedir)
        local options = {
            targetdir = targetdir,
            dir = outdir,
            metal = is_plat("macosx", "iphoneos"),
            vulkan = is_plat("macosx", "iphoneos", "windows", "linux"),
            gles = is_plat("macosx", "iphoneos", "windows", "linux"),
            batchcmds = batchcmds,
            name = name or target:name(),
        }
        batchcmds:mkdir(outdir)
        import("shaders")(sourcebatch.sourcefiles, options)
        batchcmds:add_depfiles(sourcebatch.sourcefiles)
    end)
