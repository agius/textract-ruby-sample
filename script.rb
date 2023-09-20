require_relative 'node'
require_relative 'result'
require_relative 'client'

client = TextractClient.new
result = client.analyze_document('example-table.pdf')
result.print_tree
