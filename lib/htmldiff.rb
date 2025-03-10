# frozen_string_literal: true

module HTMLDiff

  Match = Struct.new(:start_in_old, :start_in_new, :size)

  class Match
    def end_in_old
      self.start_in_old + self.size
    end

    def end_in_new
      self.start_in_new + self.size
    end
  end

  Operation = Struct.new(:action, :start_in_old, :end_in_old, :start_in_new, :end_in_new)

  class DiffBuilder
    WORDCHAR_REGEXP = /[\p{Latin}\p{Greek}\p{Cyrillic}\p{Arabic}\p{Hebrew}\d@#.-]/i

    def initialize(old_version, new_version)
      @old_version = old_version
      @new_version = new_version
      @content = []
    end

    def build
      split_inputs_to_words
      index_new_words
      operations.each { |op| perform_operation(op) }
      @content.join
    end

    def split_inputs_to_words
      @old_words = convert_html_to_list_of_words(explode(@old_version))
      @new_words = convert_html_to_list_of_words(explode(@new_version))
    end

    def index_new_words
      @word_indices = Hash.new { |h, word| h[word] = [] }
      @new_words.each_with_index { |word, i| @word_indices[word] << i }
    end

    def operations
      position_in_old = position_in_new = 0
      operations = []

      matches = matching_blocks

      # An empty match at the end forces the loop below to handle the unmatched tails
      # TODO: Refactor to handle more gracefully
      matches << Match.new(@old_words.length, @new_words.length, 0)

      matches.each do |match|
        match_starts_at_current_position_in_old = (position_in_old == match.start_in_old)
        match_starts_at_current_position_in_new = (position_in_new == match.start_in_new)

        action_upto_match_positions =
          case [match_starts_at_current_position_in_old, match_starts_at_current_position_in_new]
          when [false, false]
            :replace
          when [true, false]
            :insert
          when [false, true]
            :delete
          else
            # this happens if the first few words are same in both versions
            :none
          end

        if action_upto_match_positions != :none
          operation_upto_match_positions = Operation.new(action_upto_match_positions,
                                                         position_in_old, match.start_in_old,
                                                         position_in_new, match.start_in_new)
          operations << operation_upto_match_positions
        end

        unless match.size == 0
          match_operation = Operation.new(:equal,
                                          match.start_in_old, match.end_in_old,
                                          match.start_in_new, match.end_in_new)
          operations << match_operation
        end

        position_in_old = match.end_in_old
        position_in_new = match.end_in_new
      end

      operations
    end

    def matching_blocks
      matching_blocks = []
      recursively_find_matching_blocks(0, @old_words.size, 0, @new_words.size, matching_blocks)
      matching_blocks
    end

    def recursively_find_matching_blocks(start_in_old, end_in_old, start_in_new, end_in_new, matching_blocks)
      match = find_match(start_in_old, end_in_old, start_in_new, end_in_new)
      return unless match

      if start_in_old < match.start_in_old && start_in_new < match.start_in_new
        recursively_find_matching_blocks(start_in_old,
                                         match.start_in_old,
                                         start_in_new,
                                         match.start_in_new,
                                         matching_blocks)
      end
      matching_blocks << match
      if match.end_in_old < end_in_old && match.end_in_new < end_in_new
        recursively_find_matching_blocks(match.end_in_old,
                                         end_in_old,
                                         match.end_in_new,
                                         end_in_new,
                                         matching_blocks)
      end
    end

    def find_match(start_in_old, end_in_old, start_in_new, end_in_new)
      best_match_in_old = start_in_old
      best_match_in_new = start_in_new
      best_match_size = 0
      match_length_at = Hash.new { |h, index| h[index] = 0 }

      start_in_old.upto(end_in_old - 1) do |index_in_old|
        new_match_length_at = Hash.new { |h, index| h[index] = 0 }

        @word_indices[@old_words[index_in_old]].each do |index_in_new|
          next  if index_in_new < start_in_new
          break if index_in_new >= end_in_new

          new_match_length = match_length_at[index_in_new - 1] + 1
          new_match_length_at[index_in_new] = new_match_length

          if new_match_length > best_match_size
            best_match_in_old = index_in_old - new_match_length + 1
            best_match_in_new = index_in_new - new_match_length + 1
            best_match_size = new_match_length
          end
        end
        match_length_at = new_match_length_at
      end

      return if best_match_size == 0

      Match.new(best_match_in_old, best_match_in_new, best_match_size)
    end

    def add_matching_words_left(match_in_old, match_in_new, match_size, start_in_old, start_in_new)
      while match_in_old > start_in_old &&
            match_in_new > start_in_new &&
            @old_words[match_in_old - 1] == @new_words[match_in_new - 1]
        match_in_old -= 1
        match_in_new -= 1
        match_size += 1
      end
      [match_in_old, match_in_new, match_size]
    end

    def add_matching_words_right(match_in_old, match_in_new, match_size, end_in_old, end_in_new)
      while match_in_old + match_size < end_in_old &&
            match_in_new + match_size < end_in_new &&
            @old_words[match_in_old + match_size] == @new_words[match_in_new + match_size]
        match_size += 1
      end
      [match_in_old, match_in_new, match_size]
    end

    VALID_METHODS = %i[replace insert delete equal].freeze

    def perform_operation(operation)
      @operation = operation
      self.send(operation.action, operation)
    end

    def replace(operation)
      delete(operation, 'diffmod')
      insert(operation, 'diffmod')
    end

    def insert(operation, tagclass = 'diffins')
      insert_tag('ins', tagclass, @new_words[operation.start_in_new...operation.end_in_new])
    end

    def delete(operation, tagclass = 'diffdel')
      insert_tag('del', tagclass, @old_words[operation.start_in_old...operation.end_in_old])
    end

    def equal(operation)
      # no tags to insert, simply copy the matching words from one of the versions
      @content += @new_words[operation.start_in_new...operation.end_in_new]
    end

    def opening_tag?(item)
      item =~ %r!^\s*<[^>]+>\s*$!
    end

    def closing_tag?(item)
      item =~ %r!^\s*</[^>]+>\s*$!
    end

    def tag?(item)
      opening_tag?(item) or closing_tag?(item)
    end

    def img_tag?(item)
      (item[0..4].downcase == '<img ') && (item[-2..-1].downcase == '/>')
    end

    def extract_consecutive_words(words, &condition)
      index_of_first_tag = nil
      words.each_with_index do |word, i|
        unless condition.call(word)
          index_of_first_tag = i
          break
        end
      end

      if index_of_first_tag
        words.slice!(0...index_of_first_tag)
      else
        words.slice!(0..words.length)
      end
    end

    # This method encloses words within a specified tag (ins or del), and adds this into @content,
    # with a twist: if there are words contain tags, it actually creates multiple ins or del,
    # so that they don't include any ins or del. This handles cases like
    # old: '<p>a</p>'
    # new: '<p>ab</p><p>c</b>'
    # diff result: '<p>a<ins>b</ins></p><p><ins>c</ins></p>'
    # this still doesn't guarantee valid HTML (hint: think about diffing a text containing ins or
    # del tags), but handles correctly more cases than the earlier version.
    def insert_tag(tagname, cssclass, words)
      loop do
        break if words.empty?
        # non_tags = extract_consecutive_words(words) { |word| not tag?(word) }
        # @content << wrap_text(non_tags.join, tagname, cssclass) unless non_tags.empty?
        non_tags = extract_consecutive_words(words) { |word| (img_tag?(word)) || (!tag?(word)) }
        @content << wrap_text(non_tags.join, tagname, cssclass) unless non_tags.join.empty?

        break if words.empty?
        @content += extract_consecutive_words(words) { |word| tag?(word) }
      end
    end

    def wrap_text(text, tagname, cssclass)
      %(<#{tagname} class="#{cssclass}">#{text}</#{tagname}>)
    end

    def explode(sequence)
      sequence.is_a?(String) ? sequence.split('') : sequence
    end

    def end_of_tag?(char)
      char == '>'
    end

    def start_of_tag?(char)
      char == '<'
    end

    def wordchar?(char)
      char.match?(WORDCHAR_REGEXP)
    end

    def html_entity_char?(char)
      char.match?(/[a-zA-Z0-9#;]/)
    end

    def start_of_html_entity?(char)
      char == '&'
    end

    def convert_html_to_list_of_words(x, use_brackets = false)
      mode = :wordchar
      current_word = +''
      words = []

      x.each do |char|
        case mode
        when :tag
          if end_of_tag?(char)
            current_word << (use_brackets ? ']' : '>')
            words << current_word
            current_word = +''
            mode = :wordchar
          else
            current_word << char
          end
        when :html_entity
          current_word << char
          if char == ';'
            words << current_word
            current_word = +''
            mode = :wordchar
          elsif !html_entity_char?(char)
            # This wasn't actually an HTML entity, just an ampersand followed by non-entity chars
            # Treat it as a regular word
            words << current_word
            current_word = char
            mode = wordchar?(char) ? :wordchar : :other
          end
        when :wordchar
          if start_of_tag?(char)
            words << current_word
            current_word = use_brackets ? +'[' : +'<'
            mode = :tag
          elsif start_of_html_entity?(char)
            words << current_word
            current_word = char
            mode = :html_entity
          elsif wordchar?(char)
            current_word << char
          else
            words << current_word
            current_word = char
            mode = :other
          end
        when :other
          words << current_word
          if start_of_tag?(char)
            current_word = use_brackets ? +'[' : +'<'
            mode = :tag
          elsif start_of_html_entity?(char)
            current_word = char
            mode = :html_entity
          else
            current_word = char
            mode = :wordchar if wordchar?(char)
          end
        else
          raise "Unknown mode #{mode.inspect}"
        end
      end

      words << current_word
      words
    end
  end

  def diff(a, b)
    DiffBuilder.new(a, b).build
  end
end
