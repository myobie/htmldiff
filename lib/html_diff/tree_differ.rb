# frozen_string_literal: true

require 'nokogiri'

module HTMLDiff
  # A structure-aware HTML differ that preserves DOM integrity
  class TreeDiffer
    # Block elements that should be preserved as structural units
    BLOCK_ELEMENTS = %w[
      address article aside blockquote canvas dd div dl dt fieldset figcaption figure
      footer form h1 h2 h3 h4 h5 h6 header hr li main nav ol p pre section
      table tbody tfoot th thead tr ul video
    ].freeze

    # Generate an HTML diff between two HTML strings
    #
    # @param old_html [String] The original HTML
    # @param new_html [String] The new HTML
    # @param html_format [Hash] Hash of options for formatting the output
    # @return [String] HTML string with changes marked
    def self.diff(old_html, new_html, html_format = {})
      diff_options = html_format || {}

      # Parse HTML documents
      old_doc = parse_html(old_html)
      new_doc = parse_html(new_html)

      # Normalize and prepare documents
      normalize_nodes(old_doc)
      normalize_nodes(new_doc)

      # Generate diff
      changes = diff_trees(old_doc, new_doc)

      # Apply post-processing to ensure valid HTML
      result_doc = post_process(changes, diff_options)

      # Convert back to HTML string
      result_doc.to_html
    end

    private

    def self.parse_html(html)
      # Parse HTML with fragment to avoid adding html/body tags
      Nokogiri::HTML.fragment(html)
    end

    def self.normalize_nodes(doc)
      # Remove comments
      doc.xpath('//comment()').remove

      # Normalize whitespace in text nodes
      doc.xpath('//text()').each do |node|
        unless node.parent && BLOCK_ELEMENTS.include?(node.parent.name)
          node.content = node.content.gsub(/\s+/, ' ')
        end
      end
    end

    def self.diff_trees(old_doc, new_doc)
      # Create a working copy we can manipulate
      result_doc = old_doc.dup

      # Identify changes at each level
      compare_nodes(result_doc, new_doc)

      result_doc
    end

    def self.compare_nodes(old_node, new_node)
      # If node types differ, replace entire node
      if old_node.type != new_node.type
        replace_node(old_node, new_node)
        return
      end

      # Handle text nodes
      if old_node.text? && new_node.text?
        if old_node.content != new_node.content
          old_parent = old_node.parent

          # Replace with delete and insert tags
          del_node = Nokogiri::XML::Node.new('del', old_parent.document)
          del_node.content = old_node.content
          ins_node = Nokogiri::XML::Node.new('ins', old_parent.document)
          ins_node.content = new_node.content

          old_node.replace(del_node)
          del_node.add_next_sibling(ins_node)
        end
        return
      end

      # For element nodes, compare attributes
      if old_node.element? && new_node.element?
        # If tag names are different, replace the whole node
        if old_node.name != new_node.name
          replace_node(old_node, new_node)
          return
        end

        # Compare attributes
        # For simplicity, we're not marking attribute changes in this example
      end

      # Compare children
      compare_children(old_node, new_node)
    end

    def self.compare_children(old_parent, new_parent)
      old_children = old_parent.children.to_a
      new_children = new_parent.children.to_a

      # Use an LCS-based diff to find matching children
      # This is a simplified version that won't handle all cases
      i = 0
      j = 0

      while i < old_children.length && j < new_children.length
        old_child = old_children[i]
        new_child = new_children[j]

        if nodes_equal?(old_child, new_child)
          # Nodes match, recursively compare their children
          compare_nodes(old_child, new_child)
          i += 1
          j += 1
        elsif j + 1 < new_children.length && nodes_equal?(old_child, new_children[j + 1])
          # Current new node is an insertion
          insert_node(old_child, new_child, position: :before)
          j += 1
        elsif i + 1 < old_children.length && nodes_equal?(old_children[i + 1], new_child)
          # Current old node is a deletion
          wrap_in_delete(old_child)
          i += 1
        else
          # No good match found, treat as replacement
          replace_node(old_child, new_child)
          i += 1
          j += 1
        end
      end

      # Handle remaining old nodes (deletions)
      while i < old_children.length
        wrap_in_delete(old_children[i])
        i += 1
      end

      # Handle remaining new nodes (insertions)
      while j < new_children.length
        insert_node(old_parent, new_children[j], position: :append)
        j += 1
      end
    end

    def self.nodes_equal?(node1, node2)
      return false unless node1 && node2

      if node1.text? && node2.text?
        return node1.content.strip == node2.content.strip
      elsif node1.element? && node2.element?
        return node1.name == node2.name
      end

      false
    end

    def self.replace_node(old_node, new_node)
      old_parent = old_node.parent
      return unless old_parent

      # Create delete and insert nodes
      del_node = Nokogiri::XML::Node.new('del', old_parent.document)
      ins_node = Nokogiri::XML::Node.new('ins', old_parent.document)

      # Clone the old and new nodes to put inside del/ins
      del_content = old_node.dup
      ins_content = old_parent.document.import(new_node.dup)

      del_node.add_child(del_content)
      ins_node.add_child(ins_content)

      # Replace the old node with the del+ins pair
      old_node.replace(del_node)
      del_node.add_next_sibling(ins_node)
    end

    def self.insert_node(reference_node, new_node, position: :after)
      parent = reference_node.parent
      return unless parent

      # Create the insert node
      ins_node = Nokogiri::XML::Node.new('ins', parent.document)
      ins_content = parent.document.import(new_node.dup)
      ins_node.add_child(ins_content)

      case position
      when :before
        reference_node.add_previous_sibling(ins_node)
      when :after
        reference_node.add_next_sibling(ins_node)
      when :append
        parent.add_child(ins_node)
      end
    end

    def self.wrap_in_delete(node)
      parent = node.parent
      return unless parent

      # Create the delete node
      del_node = Nokogiri::XML::Node.new('del', parent.document)

      # Remove the node from its parent and add it to the delete node
      node_dup = node.dup
      del_node.add_child(node_dup)

      # Replace the original node with the delete node
      node.replace(del_node)
    end

    def self.post_process(doc, options)
      fix_block_elements(doc)
      fix_table_structure(doc)
      fix_list_structure(doc)
      doc
    end

    def self.fix_block_elements(doc)
      # Fix cases where ins/del tags break block element structure
      BLOCK_ELEMENTS.each do |tag|
        # Look for del/ins tags that contain block elements
        doc.css("del #{tag}, ins #{tag}").each do |node|
          # For block elements inside ins/del, we may need to restructure
          # to maintain valid HTML
          parent_change = node.parent

          # Extract this node from the parent ins/del
          parent_change.add_previous_sibling(node)

          # Wrap the extracted node in its own ins/del
          new_wrapper = Nokogiri::XML::Node.new(parent_change.name, doc)
          node.replace(new_wrapper)
          new_wrapper.add_child(node)
        end
      end
    end

    def self.fix_table_structure(doc)
      # Fix invalid table structures
      # This is a simplified version - the real implementation would be more complex

      # Remove ins/del directly inside table, tbody, thead, tfoot, tr
      %w[table tbody thead tfoot tr].each do |tag|
        doc.css("#{tag} > ins, #{tag} > del").each do |node|
          # Move contents up, replacing the ins/del
          parent = node.parent
          node.children.each do |child|
            node.add_previous_sibling(child)
          end
          node.remove
        end
      end

      # For td/th elements, move ins/del inside
      doc.css('tr > ins > td, tr > del > td, tr > ins > th, tr > del > th').each do |cell|
        change_tag = cell.parent
        change_type = change_tag.name # ins or del

        # Move cell out of ins/del
        change_tag.add_previous_sibling(cell)
        change_tag.remove

        # Create a new ins/del inside the cell
        new_change = Nokogiri::XML::Node.new(change_type, doc)
        cell.children.each do |child|
          new_change.add_child(child)
        end
        cell.add_child(new_change)
      end
    end

    def self.fix_list_structure(doc)
      # Fix invalid list structures (li must be direct children of ul/ol)
      doc.css('del > li, ins > li').each do |li|
        change_tag = li.parent
        change_type = change_tag.name # ins or del

        # Move li out of ins/del
        if change_tag.parent && %w[ul ol].include?(change_tag.parent.name)
          change_tag.add_previous_sibling(li)

          # Add a class to mark deleted list items
          if change_type == 'del'
            li['class'] = [li['class'], 'del-li'].compact.join(' ')
          end

          # Create a new ins/del inside the li
          new_change = Nokogiri::XML::Node.new(change_type, doc)
          li.children.each do |child|
            new_change.add_child(child.dup)
          end
          li.children.remove
          li.add_child(new_change)

          change_tag.remove if change_tag.children.empty?
        end
      end
    end
  end
end
