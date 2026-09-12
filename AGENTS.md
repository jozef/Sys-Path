# Repository Instructions

## Generated Documentation

`README` is generated from the POD in `lib/Sys/Path.pm`. Do not edit `README`
directly. Edit the main module first, then regenerate `README` and the
distribution metadata:

```sh
perl Build.PL && ./Build distmeta
```

Include the refreshed generated files with the source POD change.
