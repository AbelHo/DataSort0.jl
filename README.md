# DataSort0.jl

A Julia package for data repository management. It provides tools to:
- Traverse directories and collect file information
- Tabulate and store metadata about available data
- Summarize datasets
- Incrementally update a collected database as new data is added or changed

## Features
- Directory traversal and file listing
- Tabulation of file metadata (size, modification time, etc.)
- Data summarization (counts, size, date range)
- Database updating/merging

## Usage
```julia
using DataSort0

files = traverse_data("/path/to/data")
df = tabulate_data0(files)
sum = summarize_data(df)
# To update an existing database:
updated_df = update_database(old_df, df)
```

## Installation
This package is not yet registered. For development, clone the repo and use `Pkg.develop`.

## License
MIT
