# frozen_string_literal: true

require_relative 'async_partial/railtie'

module AsyncPartial
  module Renderer
    def render(context, options, block)
      if (options.delete(:async) || (options[:locals]&.delete(:async)))
        AsyncResult.new(Thread.new { super })
      else
        super
      end
    end
  end

  class AsyncResult
    def initialize(thread)
      @thread = thread
    end

    def nil?
      false
    end

    def to_s
      val = @thread.value
      @thread.kill
      val
    end
  end
end
