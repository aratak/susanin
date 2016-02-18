require "active_support/core_ext/array"
require "active_support/concern"

module Susanin

  class Resource

    def initialize(values={}, default = ->(r) {r})
      @resources = values.dup
      @default_proc = default
    end

    def url_parameters(record_or_hash_or_array, options={})
      params = Array.wrap(record_or_hash_or_array).map {|i| self.get(i) }.flatten
      merged_options(params, options={})
    end

    def get(record, resources=@resources)
      key = get_key(record)
      result = get_result(key, record, resources)
      new_resources = resources_except(resources, key)

      if result.is_a?(Array)
        result.map { |i| get(i, new_resources) }
      else
        result
      end
    end

    def pattern_params(arr)
      Pattern.new(arr)
    end

    def get_key(record)
      case record
        when Class then record
        when Array then record.map { |i| get_key(i) }
        when Symbol then record
        when String then record
        else record.class
      end
    end

    def get_result(key, record, _resources)
      pattern = pattern_params(key).first { |i| _resources.key?(i) }
      pattern ? _resources[pattern][record] : @default_proc[record]
    end

    def merged_options(params, options={})
      params = params.dup
      default_options = params.extract_options!
      params + ((default_options.any? || options.any?) ? [default_options.merge(options)] : [])
    end

    def resources_except(resources, key)
      keys = Array.wrap(key)
      new_resources = resources.dup
      new_resources.reject! { |r| keys == r || (Array.wrap(r).one? ? keys.include?(Array.wrap(r).first) : false) }
      new_resources
    end

  end

end
