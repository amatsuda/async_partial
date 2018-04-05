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

  module ArrayBuffer
    def initialize(*)
      super
      @values = []
    end

    def <<(value)
      @values << [value, :<<] unless value.nil?
      self
    end
    alias :append= :<<

    def safe_concat(value)
      raise ActiveSupport::SafeBuffer::SafeConcatError unless html_safe?
      @values << [value, :safe_concat] unless value.nil?
      self
    end
    alias :safe_append= :safe_concat

    def safe_expr_append=(val)
      @values << [val, :safe_expr_append] unless val.nil?
      self
    end

    def to_s
      result = @values.each_with_object(ActiveSupport::SafeBuffer.new) do |(v, meth), buf|
        if meth == :<<
          buf << v.to_s
        else
          buf.safe_concat(v.to_s)
        end
      end
      result.to_s
    end
  end
end
