using CSV, DataFrames

folder_labelfile = ""
label_colnames = ["Notes", "Note", "Type of bp"]

dfs = DataFrame[]; fnames = String[]

for fpath in readdir(folder_labelfile; join=true)
    occursin("raven_", basename(fpath)) && continue
    df =  CSV.read(fpath, DataFrame)
    (size(df, 2 ) < 2 || size(df,1) < 1 ) && continue
    

    if any(col -> col in names(df), label_colnames)
        # println(basename(fpath), "\t", unique(df.Notes))
        label_colname = label_colnames[findfirst(col -> col in names(df), label_colnames)]
        df.label = df[!, label_colname]
        @info label_colname
    else
        @warn "$fpath\tNo Notes column"
    end
    push!(dfs, df)
    push!(fnames, basename(fpath))
end

labels = vcat(map(x-> x.label, dfs)...)
map!(x-> (ismissing(x) || occursin("?", x)) ? "" : strip(x), labels, labels)
# remove questionable labels with character '?'
# labels = filter(x-> !ismissing(x) && !occursin("?", x), labels)
categories = labels |> CategoricalArray
lc = categories .|> levelcode

labels |> unique

# write to file
open("temp/labels.txt", "w") do io
    println(io, join(labels |> unique, '\n'))
end



CSV.write("temp/labels.csv", sort(DataFrame(label=labels, id=lc), :label))


rd = readdir(folder_labelfile; join=true)
df = CSV.read(rd[4], DataFrame)
df = CSV.read("", DataFrame)

# map(x->  , dfs)


label_fname = ""
labels = CSV.read(label_fname, DataFrame)

#### catogorizing
using CategoricalArrays
categories = labels.Notes |> CategoricalArray
labels.id = labels.Notes |> CategoricalArray .|> levelcode
#######





########################################################################
#~ from sound snippets
using Plots; plotlyjs()
summary_filepath = "temp/summary.csv"
df = CSV.read(summary_filepath, DataFrame)
filter!(row -> startswith(row.filename, "sel."), df)

labels = df.filename .|> x-> lowercase.(strip.(split(x,'.')[7:end-1])) #|> length #|> plot
open("temp/labels_snipppet.txt", "w") do io
    println(io, join( (labels |> unique) .|> x-> join(x,"|"), '\n'))
end
labels |> unique
la = vcat(labels...) |> unique
filter(x->occursin("harmonics", x), la)

filter(x->occursin("harmonics", x), labels .|> x-> join(x,"|")) |> unique .|> println

extrema(df.duration)
describe(df.duration)
df.duration |> histogram
histogram(df.duration; bins=0:0.05:80, xlabel="duration (s)", ylabel="count", title="Histogram of sound snippet durations", legend=false)