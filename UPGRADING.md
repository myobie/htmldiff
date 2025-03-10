# Upgrading HTMLDiff

## Upgrading from 0.0.1 to 1.0.0

After 15 years, HTMLDiff is back from the dead!

Version 1.0.0 does **not** break the core `HTMLDiff.diff(a, b)` API,
however, many of the internals have been refactored.
The vast majority of users will not be affected by these changes,
except for those who have monkey-patched the internals of HTMLDiff
or are referencing internal classes or methods.

The `HTMLDiff::DiffBuilder` class is now deprecated and raises a warning.
Please change usages of `HTMLDiff::DiffBuilder.new(a, b).build` to `HTMLDiff.diff(a, b)`.

Please refer to README.md for the latest usage instructions.
