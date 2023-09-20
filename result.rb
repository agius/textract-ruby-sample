class Result
  attr_reader :blocks, :warnings

  BLOCK_TYPES = %w(
    KEY_VALUE_SET
    PAGE
    LINE
    WORD
    TABLE
    CELL
    SELECTION_ELEMENT
    MERGED_CELL
    TITLE
    QUERY
    QUERY_RESULT
    SIGNATURE
    TABLE_TITLE
    TABLE_FOOTER
  )

  def initialize(blocks: [], warnings: [])
    @blocks = blocks.to_h { |blk| [blk.id, blk] }
    @warnings = warnings
  end

  def blocks_by_type(block_type)
    blocks.filter { |_id, blk| blk.block_type == block_type }
  end

  def tree
    @tree ||= blocks_by_type('PAGE').map do |_id, page_block|
      Node.new(page_block, blocks_map: blocks)
    end
  end

  def print_tree
    tree.each {|node| node.print_tree }
  end
end
