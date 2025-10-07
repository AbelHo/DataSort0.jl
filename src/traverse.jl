"""
traverse_data(dir::String) -> Vector{String}

Recursively traverse the directory `dir` and return a list of file paths.
"""
function traverse_data(dir::String)
    files = String[]
    for (root, _, fs) in walkdir(dir)
        for f in fs
            push!(files, joinpath(root, f))
        end
    end
    return files
end
