#!/usr/bin/env ruby

require 'csv'
require 'json'

UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
NUMERIC_REGEX = /\b[0-9]+\b/

# this is a report from https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/view/ad545380-7494-11ed-ae16-ef32c250fb53?_g=(filters%3A!()%2CrefreshInterval%3A(pause%3A!t%2Cvalue%3A0)%2Ctime%3A(from%3Anow-15m%2Cto%3Anow))
# set time period from 2022-12-05 10:00 UTC for every POST
# use "Reporting" > "Download CSV"
csv = CSV
      .parse(STDIN, headers: true)
      .reject { |r| r['log_processed.transaction.messages'] == '[]' }

errors = []

csv.each do |r|
  error = {}
  m = JSON.parse(r['log_processed.transaction.messages'])
  error['kind'] = m.first['message']
  error['tags'] = m.first['details']['tags'].sort

  req = r['log_processed.transaction.request.uri']
        .gsub(UUID_REGEX, '{uuid}')
        .gsub(NUMERIC_REGEX, '{number}')
  error['request'] = req

  errors << error
end

errors.group_by { |e| e['request'] }.each do |request, problems|
  puts
  puts '#{request}:'
  problems.tally { |p| p['kind'] }.each do |p,c|
    puts "  #{c} x #{p['kind']}"
  end
end
