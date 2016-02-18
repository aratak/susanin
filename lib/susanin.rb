require "active_support/core_ext/array"
require "active_support/concern"
require "active_support/dependencies/autoload"
require "susanin/version"

module Susanin
  extend ActiveSupport::Concern

  autoload :Resource, 'susanin/resource'
  autoload :Pattern, 'susanin/pattern'

  included do
    hide_action :polymorphic_url, :polymorphic_path
    helper_method :polymorphic_url, :polymorphic_path
  end

  module ClassMethods
    def susanin(content = nil, &block)
      content_proc = block_given? ? Proc.new(&block) : Proc.new { content }

      define_method :susanin do
        @susanin ||= Resource.new(*Array.wrap(instance_exec(&content_proc)))
      end
    end
  end

  def polymorphic_url(record_or_hash_or_array, options={})
    super(*susanin.url_parameters(record_or_hash_or_array, options))
  end

  def polymorphic_path(record_or_hash_or_array, options={})
    super(*susanin.url_parameters(record_or_hash_or_array, options))
  end

  def susanin
    @susanin ||= Resource.new()
  end
end
