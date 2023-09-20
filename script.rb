require_relative 'node'
require_relative 'result'
require_relative 'client'

client = TextractClient.new
client.analyze_document('example-table.pdf')
