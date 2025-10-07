"""
update_database(old_df::DataFrame, new_df::DataFrame) -> DataFrame

Update the old database with new data, handling additions and changes.
"""
function update_database(old_df::DataFrame, new_df::DataFrame)
    # Simple merge by path, preferring new info
    combined = vcat(old_df, new_df)
    unique!(combined, :path)
    return combined
end
