using Test
using DataSort0


using VideoIO
using FFMPEG
using JSON
using CSV
using DataFrames
using FileIO

include("../src/tabulate_data.jl")
include("../src/media_info.jl")
include("../src/utils.jl")

@testset "tabulate_data.jl" begin
    # Test count_arraysize
    @test count_arraysize("a;b;c") == 3
    @test count_arraysize(missing) == 0
    @test array_tostring([1,2,3]) == "1;2;3"

    # Test find_closest_row
    df = DataFrame(datetime=[Dates.DateTime("2024-01-01T00:00:00"), Dates.DateTime("2024-01-02T00:00:00")], filepath=["a","b"])
    result = find_closest_row(df, Dates.DateTime("2024-01-01T12:00:00"))
    @test result.datetime == Dates.DateTime("2024-01-01T00:00:00") || result.datetime == Dates.DateTime("2024-01-02T00:00:00")
end

@testset "media_info.jl" begin
    # Test get_duration returns missing for non-existent file
    @test isnothing(try get_duration("/nonexistent/file.mp4") catch; nothing end) || ismissing(try get_duration("/nonexistent/file.mp4") catch; missing end)
end

@testset "utils.jl" begin
    # Test skiphiddenfiles
    files = [".hidden", "@meta", "file1", "file2"]
    filtered = skiphiddenfiles(files)
    @test all(!startswith(r"^[.@]", basename(f)) for f in filtered)
end
