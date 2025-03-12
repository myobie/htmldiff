# Upgrading HTMLDiff

## Upgrading from 0.0.1 to 1.0.0

After 15 years, HTMLDiff is back from the dead!

Version 1.0.0 does **not** break the basic syntax of `HTMLDiff.diff(a, b)` API,
however, please note the following changes:

#### Simplification of Default HTML Tags

The output diff HTML will now simple `<ins>` and `<del>` tags by default,
**without** adding the HTML classes `diffins` and `diffdel`, `diffmod`.

```ruby
HTMLDiff.diff('Sad', 'Happy')

# Old output
'<del class="diffmod">Sad</del><ins class="diffmod">Happy</ins>'

# New output
'<del>Sad</del><ins>Happy</ins>'
```

To get the exact legacy behavior, use:

```ruby
html_format = { class_insert: 'diffins', class_delete: 'diffdel', class_replace: 'diffmod' }
HTMLDiff.diff(old_text, new_text, html_format: html_format)
```

#### Refactor and Removal of Old Class Structure

Most legacy classes have been removed or refactored. For compatibility purposes,
the `HTMLDiff::DiffBuilder` class has been kept but is now deprecated and raises a warning.
Please change usages as follows:

```ruby
# Old
HTMLDiff::DiffBuilder.new(a, b).build

# Replace with
HTMLDiff.diff(a, b)
```

#### Tweaks to Diff Algorithm

The diff algorithm has been switched to use the `diff-lcs` gem which fixes many bugs,
but may result in slightly different output in some cases.

Please refer to README.md for the latest usage instructions and examples of how
to tweak and customize HTMLDiff.
