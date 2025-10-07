"""
summarize_data(df::DataFrame) -> Dict

Summarize the tabulated data.
"""
function summarize_data(df::DataFrame)
    return Dict(
        :n_files => nrow(df),
        :total_size => sum(df.size),
        :earliest => minimum(df.mtime),
        :latest => maximum(df.mtime)
    )
end
