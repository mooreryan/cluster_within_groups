# Cluster Within Groups

Cluster sequences within groups using MMseqs2

## Install

You must have a working OCaml compiler toolchain and Dune.

Download/clone the repo, ensure you have met the deps, and install:

```
# Clone repo
$ git clone https://github.com/mooreryan/cluster_within_groups
$ cd cluster_within_groups

# Install deps
$ opam install . --deps-only --with-doc --with-test

# Compile and install script
$ just install
```

If you don't have `just`, you can do `dune runtest && dune build --profile=release && dune install`.

If you are building on your computer and sending the resulting executable to biomix, you probably will hit libc version issues. In this case, use the bytecode artifact in `_build/default/bin/cluster_with_groups.bc`. You will need to run it like so: `ocamlrun cluster_withing_groups.bc --help`.

## Usage

Run `cluster_within_groups --help` for more info.

Note: there is a fun mode that attempts to get each group clustered down to a target number of sequences.

## License

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/pasv)

Copyright (c) 2023 Ryan M. Moore

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.
