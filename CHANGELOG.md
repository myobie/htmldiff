# HTMLDiff Change Log

Refer to [UPGRADING.md](UPGRADING.md) for detailed upgrade instructions.

## 1.0.0

- Switched diff algorithm to use [diff-lcs](https://github.com/halostatue/diff-lcs) gem, which fixes many bugs.
- Remove `"diffdel"`, `"diffins"`, and `"diffmod"` classes on the default output of `HTMLDiff`.
- Added multi-language support (Cyrillic, Greek, Arabic, Hebrew, Chinese, Japanese, Korean, etc.)
- Added support for HTML formatting via `HTMLDiff.diff html_format: { tag: 'span', class_insert: 'diff-ins', class_delete: 'diff-del' }`, etc. keyword args.
- Added support for custom formatter via `HTMLDiff.diff :formatter` keyword arg.
- Added support for custom tokenizer via `HTMLDiff.diff :tokenizer` keyword arg.
- Added `HTMLDiff.diff :merge_threshold` keyword arg to control how neighoring diff elements are combined.
- Added special tokenization for HTML tags, HTML entities, URLs, and email addresses.
- Split classes into separate files for better organization.
- Lots of refactors and added tests.
- Added Rubocop.
- Added Github CI.

## 0.0.1

- Initial release.
