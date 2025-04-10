# HTMLDiff

[![Gem Version](https://badge.fury.io/rb/htmldiff.svg)](https://badge.fury.io/rb/htmldiff)
[![CI](https://github.com/myobie/htmldiff/actions/workflows/ci.yml/badge.svg)](https://github.com/myobie/htmldiff/actions/workflows/ci.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

HTMLDiff is a Ruby gem that generates HTML-formatted diffs between two text strings.
It can be used in your app to highlight additions, deletions, and modifications
of text using HTML and CSS.

### Features

- Simple and opinionated API—it just works™
- Generates diffs of text using the LCS (Longest Common Subsequence) algorithm, tweaked to produce "chunkier" diff sequences.
- Diff preserves whitespace and HTML tags, HTML entities, URLs, and email addresses.
- Multi-language support (Cyrillic, Greek, Arabic, Hebrew, Chinese, Japanese, Korean, etc.)
- Customizable output formatting (see examples below).

### Alternatives

- [diffy](https://github.com/samg/diffy) - Far more complex and feature-rich, but less opinionated.
- [diff-lcs](https://github.com/halostatue/diff-lcs) - The underlying gem used by HTMLDiff.

## Getting Started

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'htmldiff'
```

### Basic Usage

```ruby
require 'htmldiff'

old_text = "The quick red fox jumped over the dog."
new_text = "The red fox hopped over the lazy dog."

diff = HTMLDiff.diff(old_text, new_text)
```

Output:

```html
The <del>quick </del>fox <del>jumped</del><ins>hopped</ins> over the <ins>lazy</ins> dog.
```

### Formatting the HTML Output

HTMLDiff includes a highly customizable `HtmlFormatter` that gives you fine-grained control over the HTML output. This formatter allows you to specify different HTML tags and CSS classes for various diff elements.

```ruby
old_text = "The quick red fox jumped over the dog."
new_text = "The red fox hopped over the lazy dog."

diff = HTMLDiff.diff(old_text, new_text, html_format: {
  tag: 'span',
  class_delete: 'highlight removed',
  class_insert: 'highlight added'
})
```

Output:

```html
The <span class="highlight removed">quick </span>red fox <span class="highlight removed">jumped</span><span class="highlight added">hopped</span> over the <span class="highlight added">lazy</span> dog.
```

#### HTML Output Customization Options

`HTMLDiff.diff(html_format:)` supports the following options:

| Option                  | Description                                                                                                |
|-------------------------|------------------------------------------------------------------------------------------------------------|
| `:tag`                  | Base HTML tag to use for all change nodes (default: none)                                                  |
| `:tag_delete`           | HTML tag for deleted content (overrides `:tag`, default: `"del"`)                                          |
| `:tag_insert`           | HTML tag for inserted content (overrides `:tag`, default: `"ins"`)                                         |
| `:tag_replace`          | HTML tag for replaced content (overrides `:tag_delete`, `:tag`)                                            |
| `:tag_replace_delete`   | HTML tag for deleted content in replacements (overrides `:tag_replace`, `:tag_delete`, `:tag`)             |
| `:tag_replace_insert`   | HTML tag for inserted content in replacements (overrides `:tag_replace`, `:tag_insert`, `:tag`)            |
| `:tag_unchanged`        | HTML tag for unchanged content (optional)                                                                  |
| `:class`                | Base CSS class(es) for all change nodes                                                                    |
| `:class_delete`         | CSS class(es) for deleted content (overrides `:class`)                                                     | 
| `:class_insert`         | CSS class(es) for inserted content (overrides `:class`)                                                    |
| `:class_replace`        | CSS class(es) for replaced content (overrides `:class_delete`, `:class_insert`, `:class`)                  |
| `:class_replace_delete` | CSS class(es) for deleted content in replacements (overrides `:class_replace`, `:class_delete`, `:class`)  |
| `:class_replace_insert` | CSS class(es) for inserted content in replacements (overrides `:class_replace`, `:class_insert`, `:class`) |
| `:class_unchanged`      | CSS class(es) for unchanged content (optional)                                                             |

#### Example: Wrapping unchanged text in tags

```ruby
diff = HTMLDiff.diff(old_text, new_text, html_format: {
  tag_unchanged: 'span',
  class_unchanged: 'unchanged',
  tag: 'span',
  class_delete: 'deleted',
  class_insert: 'inserted'
})
```

Output:

```html
<span class="unchanged">The </span><span class="deleted">quick </span><span class="unchanged">red fox </span><span class="deleted">jumped</span><span class="inserted">hopped</span><span class="unchanged"> over the </span><span class="inserted">lazy</span><span class="unchanged"> dog.</span>
```

#### Example: Special handling for replacements

```ruby
diff = HTMLDiff.diff(old_text, new_text, html_format: {
  tag_delete: 'span',
  tag_insert: 'div',
  tag_replace: 'mark',
  class_delete: 'deleted',
  class_insert: 'inserted',
  class_replace_delete: 'replaced deleted',
  class_replace_insert: 'replaced inserted'
})
```

Output:

```html
The <span class="deleted">quick </span>red fox <mark class="replaced deleted">jumped</mark><mark class="replaced inserted">hopped</mark> over the <div class="inserted">lazy</div> dog.
```

### Using a Custom Output Formatter

If the HTML formatting options above aren't sufficient for your use case,
or if you'd like to output to an alternative format (e.g. XML, JSON, etc.),
you can further customize the output by creating your own formatter.

Your formatter may be any object that responds to the `#format` method,
and it can return whatever object type you'd like (typically a String).

```ruby
module MyCustomFormatter
  def self.format(changes)
    changes.each_with_object(+'') do |(action, old_string, new_string), content|
      case action
      when '=' # equal
        content << new_string if new_string
      when '-' # remove
        content << %(<removed>#{old_string}</removed>) if old_string
      when '+' # add
        content << %(<added>#{new_string}</added>) if new_string
      when '!' # replace
        content << %(<removed>#{old_string}</removed>) if old_string
        content << %(<added>#{new_string}</added>) if new_string
      end
    end
  end
end

# Test your custom formatter
example_changes = [
  ['=', 'The ', 'The '],
  ['+', nil, 'quick '],
  ['=', 'red fox ', 'red fox '],
  ['!', 'jumped', 'hopped'],
  ['=', ' over the ', ' over the '],
  ['-', 'lazy ', nil],
  ['=', 'dog.', 'dog.']
]
MyCustomFormatter.format(example_changes)
#=> "The <added>quick </added>red fox <removed>jumped</removed>" \
#   "<added>hopped</added> over the <removed>lazy </removed>dog."

# Use your custom formatter in the diff method
diff = HTMLDiff.diff(old_text, new_text, formatter: MyCustomFormatter)
```

### Using a Custom Tokenizer

You can customize how text is split into tokens by creating your own tokenizer.
A tokenizer can be any object that responds to the `#tokenize` method and returns
an Array of Strings (i.e. the tokens).

It is useful to think of tokens as the "unsplittable" unit in your diff. For example,
if you tokenize each word `["Hello", "beautiful", "world"]`, the diff output will
never split these mid-word. However, if you tokenize each character `["H", "e", "l", "l", "o"]`,
the diff output can split words mid-character, for example, `HTMLDiff.diff("Hello", "Help", tokenizer: ...)` would
return `"Hel<del>lo</del><ins>p</ins>"`.

Your custom tokenizer's output array should include whitespace tokens, such that the output
can be joined to match the original string.

```ruby
module MyCustomTokenizer
  def self.tokenize(string)
    string.split(/(\b|\s)/).reject(&:empty?)
  end
end

# Check that your tokenizer output matches the original string when joined
test = MyCustomTokenizer.tokenize("Hello, world!") #=> ["Hello", ",", " ", "world", "!"]
test.join #=> "Hello, world!"

# Use your custom tokenizer in the diff method
diff = HTMLDiff.diff(old_text, new_text, tokenizer: MyCustomTokenizer)
```

### Tweaking Diff Chunkiness vs. Choppiness

The `:merge_threshold` option allows you to control how diff segments are joined together
with unchanged words in the middle. A higher `:merge_threshold` value will produce "chunkier"
diffs, because more words will be grouped together into each insertion or deletion group.
Conversely, a low `:merge_threshold` value will produce "choppier" diffs. This is best
illustrated by an example:

```ruby
old_text = "The quick fox jumped over the dog."
new_text = "The slow fox hopped over the dog."

# Default merge_threshold is 5. In the example below, the diff will include the
# word "fox" into the changes, because the substring " fox " is 5 characters long.
diff = HTMLDiff.diff(old_text, new_text)
diff == "The <del>quick fox jumped</del><ins>slow fox hopped</ins> over the dog."

# If we set the merge_threshold to 0, the diff will not include "fox" in the changes;
# the diff will now be more granular/choppy.
diff = HTMLDiff.diff(old_text, new_text, merge_threshold: 0)
diff == "The <del>quick</del><ins>slow</ins> fox <del>jumped</del><ins>hopped</ins> over the dog."
```

Note the value `merge_threshold: 0` will still merge whitespace, but not other characters.
To disable merging across whitespace, set `merge_threshold: false` or `-1`.

## How HTMLDiff Works

HTMLDiff uses a three-step process:

1. **Tokenization**: The input strings are broken into an array of tokens by the `HTMLDiff::Tokenizer` module.
2. **Diff Generation**: The `HTMLDiff::Differ` module uses the LCS (Longest Common Subsequence) algorithm to find the differences between the token arrays.
3. **Formatting**: The differences are formatted into HTML by a formatter.

## About HTMLDiff

### Maintainers

HTMLDiff is maintained by the team at [TableCheck](https://www.tablecheck.com/en/join/)
based in Tokyo, Japan. We use HTMLDiff in our products to help our restaurant users
visualize the edit history of their customer and reservation data. If you're seeking
your next career adventure, [we're hiring](https://careers.tablecheck.com/)!

### Acknowledgements

Original implementation by Nathan Herald, based on an unknown Wiki article.

HTMLDiff uses the fantastic [diff-lcs](https://github.com/halostatue/diff-lcs) gem under the hood.

### License

This project is licensed under the [MIT License](LICENSE).
