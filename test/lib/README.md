# Long running lib tests

Long running tests that cluster files large enough to take a while.

Keep each of these tests in its own library and dune will run them in parallel.

For now `--threads=2` is the best mmseqs option when these are run at the same time.
