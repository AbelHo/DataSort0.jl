import FileIO, FileIO.load

showall(x) = show(stdout, "text/plain", x)

function skiphiddenfiles(list)
    filter(!startswith(r"^[.@]") ∘  basename, list)
end

function savejld(savefname; kwargs...)
    if !Sys.islinux()
        jldsave(savefname; kwargs...)
    #@error(err)
    #@error("Cant save jld2 file, saving locally and copying instead")
    #rm(joinpath(res_dir, splitext(basename(aufname))[1] *"_t"*string(thresh)*"_d"*string(dist)*".jld2"))
    else
        jldsave(joinpath("", savefname|>basename); kwargs...)
        mv(joinpath("", savefname|>basename), savefname; force=true)
    end
    @info "Saved to: " * savefname
end

function FileIO.load(filenames::Array{String,1}; kwargs...)
    merge( load.(filenames; kwargs...)...)
end

"""
    process_files(folname; func=(a,b)->x, arg=nothing, no_overwrite_func=nothing)

Process files within a directory tree starting from `folname`.

# Arguments
- `folname::String`: The root directory from which to start processing files.
- `func`: A function to be applied to each file. It should accept two arguments: the source path and the destination path. It defaults to a function that does nothing.
- `arg::Union{Nothing, String}`: An optional argument. If it is a string, it is treated as a directory path, and `mkpath` is called to ensure this directory exists. This path is used as the base for the destination path in `func`.
- `no_overwrite_func`: An optional function that determines whether to overwrite existing files. It should accept the same arguments as `func`.

# Behavior
- Iterates over every file in the directory tree rooted at `folname`.
- For each file, it constructs a source path (from `folname`) and a destination path (from `arg`).
- It then attempts to apply `func` to these paths. If `func` fails, it tries to call `func` without the `no_overwrite_func` argument. If this also fails, it logs the error.

# Example
```julia
process_files("path/to/source", func=(src, dst) -> copy(src, dst), arg="path/to/destination")
"""
function process_files(folname; func=(a,b)->x, arg=nothing, no_overwrite_func=nothing)
    arg isa String && mkpath(arg)
    for (root, dirs, files) in walkdir(folname)
        # println("Directories in $root")
        # for dir in dirs
        #     println(joinpath(root, dir)) # path to directories
        #     try
        #         func(joinpath(root, dir), joinpath(arg, dir); no_overwrite_func=no_overwrite_func)
        #     catch err
        #         try 
        #             func(joinpath(root, dir), joinpath(arg, dir))
        #         catch err
        #             @error exception=(err, catch_backtrace())
        #             @error (joinpath(root, dir), joinpath(arg, dir))
        #         end
        #     end
        # end
        # println("Files in $root")
        for file in files
            println(joinpath(root, file)) # path to files
            try
                # @info joinpath(root, file), joinpath(arg, file)
                func(joinpath(root, file), joinpath(arg, file); no_overwrite_func=no_overwrite_func)
            catch err
                try 
                    func(joinpath(root, file), joinpath(arg, file))
                catch err
                    @error exception=(err, catch_backtrace())
                    @error (joinpath(root, file), joinpath(arg, file))
                end
            end
        end
    end
end

function replace_suffix(src::AbstractString, suffix, replacement=""; preview=true, kwargs...)
    if isdir(src) 
        replace_suffix.(readdir(src; join=true), Ref(suffix), Ref(replacement); preview=preview, kwargs...)
        return
    end

    splitted = splitext(src)
    if endswith(splitted[1], suffix)
        @info splitted, suffix
        indices_of_suffix = findlast(suffix, splitted[1])
        isempty(indices_of_suffix) && return
        
        dst = splitted[1][first:[1]-1] * replacement * splitted[2]
        if preview
            println(basename(src) *"\t"* basename(dst))
            return
        end
        mv(src, dst; kwargs...)
    end
end

# Function to search for files with specific string and suffix, then run a function on threshold_impulsive
function func_on(a, b; needle="", filetype="", prefix="", func=(x,y)->nothing, verbose=false)
    fname = basename(a)
    verbose && print("\t",a,b, "\n")
    if occursin(needle, fname) && endswith(fname, filetype) && startswith(fname, prefix)
        func(a, joinpath(b, fname))
    end
end

"""
# Transfer some files to a new folder with the same folder structure as the original folder.
# example:
infol = ""
outfol = ""
# func_new(x, y) = func_on(x, y; needle="cps40.0", filetype=".txt", func=(a,b)->print("\t",a,"  ",b,"\n"), verbose=false)
# transfer raven files
func_new(x, y) = func_on(x, y; prefix="raven_", needle="cps40.0", filetype=".txt", func=cp, verbose=false)
process_files_hierarchy_with_func(infol, outfol; func=func_new)#verbose=true)
# transfer counts.csv files
func_new(x, y) = func_on(x, y; prefix="counts", needle="", filetype=".csv", func=cp, verbose=false)
process_files_hierarchy_with_func(infol, outfol; func=func_new)#verbose=true

count_files = glob("*/counts.csv", infol) |> sort
df = CSV.read.(count_files, DataFrame)
select!(df[2], Not(:filepath)); df = vcat(df...)
CSV.write(joinpath(outfol, "counts_all.csv"), df)
# df = vcat(CSV.read.(count_files, DataFrame)...)
"""
function process_files_hierarchy_with_func(folname, outfolder, args...; verbose=false, func=(x,y)->nothing, flag_skiphiddenfiles=true, kwargs...)
    flist = readdir(folname; join=true) 
    flag_skiphiddenfiles && (flisth = flist |> skiphiddenfiles)
    for file in flist
        if isdir(file)
            @info "directory: $file"
            mkpath(joinpath(outfolder, basename(file)))
            process_files_hierarchy_with_func( file, joinpath(outfolder, basename(file)), args...; 
                func=func, verbose=verbose, flag_skiphiddenfiles=flag_skiphiddenfiles, kwargs...)
        else
            verbose && print("file: $file, outfolder: $outfolder\n")
            func(file, outfolder, args...; kwargs...)
        end
    end
end


# using Glob
# """
    # make_clip_index_html(folder)# flag_sort_number=false)#; outname="index.html", prefix="clip_")
# """
function make_clip_index_html(folder::AbstractString; outname="index2.html", prefix="clip_", flag_sort_number=true, output_type="html")
    # Extract number from filename for sorting
    function clipnum(f)
        m = match(Regex("^" * prefix * "(\\d+)\\.$output_type\$"), basename(f))
        isnothing(m) ? typemax(Int) : parse(Int, m.captures[1])
    end

    files = filter(f -> occursin(Regex("^" * prefix * "\\d+\\.$output_type\$"), basename(f)), readdir(folder; join=true))
    if flag_sort_number 
        files = sort(files, by=clipnum)
    else
        files = sort(files)
    end
    outpath = joinpath(dirname(folder), outname)

    open(outpath, "w") do io
        println(io, "<!DOCTYPE html>\n<html>\n<head><title>Clips Index</title></head>\n<body>")
        for f in files
            fname = basename(f)
            relpath = joinpath(basename(folder), fname)
            println(io, """<h3>$fname</h3>""")
            if output_type in ["png", "jpg", "jpeg", "gif", "webp", "svg", "svg", "bmp", "tiff"]
                println(io, """<img src="$relpath" alt="$fname" style="max-width:100%; height:auto;">""")
            else
                println(io, """<iframe src="$relpath" width="100%" height="400" style="border:none;margin-bottom:1em;"></iframe>""")
            end
        end
        println(io, "</body>\n</html>")
    end
    return outpath
end



"""
    run_func_fileauto(dname, outfolder; sensor_names=["acoustic", "topview", "uw1"], sensor_filetypes=[".ogg", ".mkv", ".mkv"], func=x->x, prefix_filter="", kwargs...)

Process files in a directory `dname` based on specified `sensor_names` and `sensor_filetypes`, applying a function `func` to each file group and outputting the results to `outfolder`.

# Arguments
- `dname::String`: The directory name where the source files are located.
- `outfolder::String`: The output directory where the processed files will be saved.
- `sensor_names::Array{String}`: An array of sensor names, used to identify groups of files. Defaults to `["acoustic", "video1", "video2"]`.
- `sensor_filetypes::Array{String}`: An array of file extensions corresponding to each sensor name. Defaults to `[".ogg", ".mkv", ".mkv"]`.
- `func`: A function to be applied to each group of files. It defaults to an identity function (`x->x`). The function should accept file paths as arguments and any number of keyword arguments (`kwargs`).
- `prefix_filter::String`: A string filter to apply to filenames, selecting only those that start with the specified prefix. Defaults to an empty string, which selects all files.
- `kwargs...`: Additional keyword arguments to be passed to `func`.

# Behavior
- Creates the `outfolder` if it does not exist.
- Iterates over files in the first sensor's directory (`sensor_names[1]`), filtering by `prefix_filter`.
- Constructs a group of file paths for each sensor based on the common prefix and specified file types.
- Applies `func` to each group of file paths, passing `outfolder` and any `kwargs` as arguments.
- Logs an error if `func` fails to process a group of files.

# Example
template function:
    ```
    stack_audio_videos(aufname, v1, v2, res_dir; kwargs...)
    ```
```julia
run_func_fileauto("data", "processed", func=(files..., outfolder; kwargs...) -> println("Processing: ", files, " into ", outfolder), prefix_filter="2021_")
"""
function run_func_fileauto(dname, outfolder,
    sensor_names = ["acoustic", "topview", "uw1"], sensor_filetypes = [".ogg", ".mkv", ".mkv"];
    func=x->x, prefix_filter="", kwargs...)

    mkpath(outfolder)
    # dname = dirname(firstfolder)
    for fname in readdir(joinpath(dname, sensor_names[1]))|>skiphiddenfiles |> x->filter(startswith(prefix_filter), x) #FIXME will fail in year 2100 onwards
        fname_split = splitext(fname)[1]
        fname_split = fname_split[1:findlast('_', fname_split)-1]

        # thisfiletype = fname_split[2]
        # fname_split = fname_split[1]
        # if thisfiletype != filetype
        #     continue
        # end
        @info fname

        try
            # @info joinpath.(Ref(dname),sensor_names,fname_split .* "_" .* sensor_names .* sensor_filetypes)
            func(joinpath.(Ref(dname),sensor_names,fname_split .* "_" .* sensor_names .* sensor_filetypes)..., outfolder; kwargs...)
        catch err
            @error "ERROR run_func_fileauto"
            @error exception=(err, catch_backtrace())
        end
    end
end

"""
    print out the argument of a this function
"""
print_args(args...) = println(args)

"""
# Example
process_files(""; func=(a,b)->template_func(a,b; template=["Ambient_", ".png"], func=cp), arg="/Volumes/data/Concretecho/data/temp/Ambient_pic") 
"""
function template_func(fp, res_file=""; template=[""], func=x->x)
    fn = basename(fp)
    if startswith(fn, template[begin]) && length(template)>1 && endswith(fn, template[end])
        @info (fp, res_file)
        return func(fp, res_file)
    end
end

# macro threaded(expr)
#     if expr.head == :comprehension
#         @info expr[1]
#         loop_vars = expr.args[2]
#         body = expr.args[1]
#         return :(
#             let
#                 items = collect($(esc(loop_vars)))
#                 Threads.@threads for i in eachindex(items)
#                     items[i] = $(esc(body))
#                 end
#                 items
#             end
#         )
#     else
#         throw(ArgumentError("The @parallel_comprehension macro expects a comprehension expression."))
#     end
# end
# Convert Dict to NamedTuple
dict2namedtuple(d) = NamedTuple(Symbol(k) => v for (k, v) in d)

function find_files_with_string(folname, str)
    files = readdir(folname; join=true) |> filter(contains(str))
    if isempty(files)
        @warn "No files found containing $str in $folname"
    end
    return files
end
function find_files_with_suffix(folname, suffix)
    files = readdir(folname; join=true) |> filter(endswith(suffix))
    if isempty(files)
        @warn "No files found with suffix $suffix in $folname"
    end
    return files
end

readdirjoin(x) = readdir(x; join=true)

@info "end utils.jl"