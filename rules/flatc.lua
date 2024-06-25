rule("flatc")
    set_extensions(".fbs")
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("lib.detect.find_tool")
        local flatc = find_tool("flatc")
        local sourcedir = path.directory(sourcefile)
        local outdir = path.join(vformat("$(buildir)"), "flat_generate", sourcedir)
        batchcmds:mkdir(outdir)
        batchcmds:vrunv(flatc.program, {
            "--cpp",
            "--gen-object-api",
            "--filename-suffix",
            "_flatbuffers",
            "-o",
            outdir,
            sourcefile,
        })
        batchcmds:show_progress(opt.progress, "${color.build.object}flatc %s", sourcefile)
        batchcmds:add_depfiles(sourcefile)
    end)
