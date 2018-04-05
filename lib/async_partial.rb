# frozen_string_literal: true

require_relative 'async_partial/railtie'

module AsyncPartial
  module Renderer
    def render(context, options, block)
      if (options.delete(:async) || (options[:locals]&.delete(:async)))
        Thread.new { super }
      else
        super
      end
    end
  end
end
