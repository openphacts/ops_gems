########################################################################################
#
# The MIT License (MIT)
# Copyright (c) 2012 BioSolveIT GmbH
#
# This file is part of the OPS gem, made available under the MIT license.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For further information please contact:
# BioSolveIT GmbH, An der Ziegelei 79, 53757 Sankt Augustin, Germany
# Phone: +49 2241 25 25 0 - Email: license@biosolveit.de
#
########################################################################################

require 'active_support/core_ext/string/inflections'

module OPS
  class LDC

    NON_PROPERTY_KEYS = %w(_about exactMatch inDataset isPrimaryTopicOf).freeze unless defined?(NON_PROPERTY_KEYS)

    # process pharmacology paginated results
    def self.parse_paginated_json(json)
      items = json['result'].delete('items')
      paginated_result = parse_item(json['result'])

      result = paginated_result
      result[:items] = items.collect{|item| parse_item(item, true)}
      result
    end

    def self.parse_primary_topic_json(json)
      primary_topic = json['result']['primaryTopic']

      # process count request results
      if primary_topic.has_key?('targetPharmacologyTotalResults')
        return {:uri => primary_topic['_about'], :count => primary_topic['targetPharmacologyTotalResults']}
      elsif primary_topic.has_key?('compoundPharmacologyTotalResults')
        return {:uri => primary_topic['_about'], :count => primary_topic['compoundPharmacologyTotalResults']}
      # process all other results
      else
        return parse_primary_topic_hash(primary_topic)
      end
    end

  private

    def self.parse_primary_topic_hash(primary_topic)
      if primary_topic.has_key?('inDataset')
        result = { primary_topic['inDataset'].to_sym => parse_item(primary_topic) }
        primary_topic['exactMatch'].each do |item|
          next unless item.is_a?(Hash)
          next unless item.has_key?('inDataset')
          result[item['inDataset'].to_sym] = parse_item(item)
        end
      else
        result = parse_item(primary_topic)
      end

      result
    end

    def self.parse_item(item, include_exact_matches=false)
      properties = {}
      properties[:uri] = item['_about'] if item['_about'].present?

      if include_exact_matches and item.has_key?('exactMatch')
        exact_matches = item['exactMatch'].is_a?(Array) ? item['exactMatch'] : [item['exactMatch']]
        exact_matches.each do |match|
          next unless match.has_key?('inDataset')
          properties[match['inDataset'].to_sym] = parse_item(match)
        end
      end

      item.each do |key, value|
        next if NON_PROPERTY_KEYS.include?(key)
        if value.is_a?(Hash) and value.has_key?('_about')
          properties[key.underscore.to_sym] = parse_item(value, include_exact_matches)
        elsif value.is_a?(Array)
          properties[key.underscore.to_sym] = value.collect{|e| e.is_a?(Hash) ? parse_item(e, include_exact_matches) : e}
        else
          properties[key.underscore.to_sym] = value
        end
      end
      properties
    end

  end
end
