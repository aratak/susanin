require "susanin/version"

module Susanin
  extend ActiveSupport::Concern

  included do
    hide_action :polymorphic_url, :polymorphic_path
    helper_method :polymorphic_url, :polymorphic_path
  end

  class Resource

    def initialize(values={}, default = ->(resource) { resource })
      @resources = values.dup
      @resources.default = default
    end

    def get(record, resources=@resources)
      result = resources[get_key(record)][record]

      if result.is_a?(Array)
        result.map { |i| get(i, resources.except(get_key(record))) }
      else
        result
      end
    end

    protected

    def get_key(record)
      case record
        when Symbol, String then record
        else record.class
      end
    end

  end

  module ClassMethods
    def susanin(content = nil)
      content_proc = if block_given?
                       Proc.new
                     else
                       Proc.new { content }
                     end
      define_method :susanin do
        @susanin ||= Resource.new(*Array.wrap(instance_exec(&content_proc)))
      end
    end
  end

  def polymorphic_url(record_or_hash_or_array, options={})
    parameters = Array.wrap(record_or_hash_or_array).map {|i| susanin.get(i) }.flatten
    default_options = parameters.extract_options!
    super(parameters, default_options.merge(options))
  end

  def polymorphic_path(record_or_hash_or_array, options={})
    parameters = Array.wrap(record_or_hash_or_array).map {|i| susanin.get(i) }.flatten
    default_options = parameters.extract_options!
    super(parameters, default_options.merge(options))
  end

  def susanin
    @susanin ||= Resource.new()
  end
end
