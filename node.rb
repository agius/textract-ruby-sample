class Node
  attr_reader :block, :parent, :children

  RELATIONSHIP_TYPES = %w(
    VALUE
    CHILD
    COMPLEX_FEATURES
    MERGED_CELL
    TITLE
    ANSWER
    TABLE
    TABLE_TITLE
    TABLE_FOOTER
  )

  def initialize(block, parent: nil, blocks_map: {})
    @block = block
    @parent = parent
    @children = []
    return if block.relationships.nil?

    block.relationships.each do |rel|
      next unless rel.type == 'CHILD'
      next if rel.ids.nil? || rel.ids.empty?

      rel.ids.each do |block_id|
        blk = blocks_map[block_id]
        next if blk.nil?

        @children << self.class.new(blk, parent: self, blocks_map: blocks_map)
      end
    end
  end

  def to_s
    txt = if block.text.nil?
      ''
    elsif block.text.length > 10
      "#{block.text[0..7]}..."
    else
      block.text
    end
    "<#{block.block_type} #{txt} #{block.id}>"
  end

  def print_tree(indent = 0)
    indent_txt = indent > 0 ? ' ' * (indent * 2) : ''
    puts "#{indent_txt}#{to_s}"
    children.each {|chld| chld.print_tree(indent + 1) }
  end
end
