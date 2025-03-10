# HTMLDiff Change Log

## 1.0.0

- Switched diff algorithm to use diff-lcs gem, which fixes many bugs.
- Added multi-language support (Cyrillic, Greek, Arabic, Hebrew, Chinese, Japanese, Korean, etc.)
- Added support for custom formatter via `HTMLDiff.diff :formatter` keyword arg.
- Added support for custom tokenizer via `HTMLDiff.diff :tokenizer` keyword arg.
- Added special tokenization for HTML tags, HTML entities, URLs, and email addresses.
- Split classes into separate files for better organization.
- Lots of refactors and added tests.
- Added Rubocop.
- Added Github CI.

## 0.0.1

- Initial release.
