"""
tabulate_data(files::Vector{String}) -> DataFrame

Tabulate file metadata for a list of files.
"""
function tabulate_data0(files::Vector{String})
    df = DataFrame(path=String[], size=Int[], mtime=DateTime[])
    for f in files
        stat = stat(f)
        push!(df, (f, stat.size, stat.mtime))
    end
    return df
end
