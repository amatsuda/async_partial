# frozen_string_literal: true

require_relative 'async_partial/railtie'

module AsyncPartial
  class << self
    def executor
      @executor ||= Concurrent::ThreadPoolExecutor.new(min_threads: [2, Concurrent.processor_count - 1].max, max_threads: [2, Concurrent.processor_count - 1].max, max_queue: 0)
    end
  end

  module PartialRenderer
    private

    def render_partial
      if @locals.delete :async
        AsyncResult.new { super }
      else
        super
      end
    end

    def collection_with_template
      super.map! do |v|
        AsyncPartial::AsyncResult === v ? v.value : v
      end
    end
  end

  module CollectionPartialTemplateRenderer
    def render(view, locals, buffer = nil, &block)
      locals = locals.dup
      if locals.delete :async
        AsyncResult.new { super }
      else
        super
      end
    end
  end

  module PerThreadBufferStack
    def render(view, locals, buffer = nil, &block)
      buffer ||= ActionView::OutputBuffer.new
      (Thread.current[:output_buffers] ||= []).push buffer
      super
    ensure
      Thread.current[:output_buffers].pop
    end
  end

  module CaptureHelper
    def capture(*args, &block)
      buf = Thread.current[:output_buffers].last
      value = nil
      buffer = with_output_buffer(buf) { value = block.call(*args) }
      if (string = buffer.presence || value) && string.is_a?(String)
        ERB::Util.html_escape string
      end
    end

    # Simply rewind what's written in the buffer
    def with_output_buffer(buf = nil) #:nodoc:
      buffer_values_was = buf.buffer_values.clone
      yield
      buffer_values_was.each {|e| buf.buffer_values.shift if buf.buffer_values[0] == e}
      buf.to_s
    ensure
      buf.buffer_values = buffer_values_was
    end
  end

  module FutureUrlHelper
    def link_to(name = nil, options = nil, html_options = nil, &block)
      if ((Hash === options) && options.delete(:async)) || ((Hash === html_options) && html_options.delete(:async))
        AsyncResult.new { super }
      else
        super
      end
    end
  end

  class AsyncResult
    def initialize(&block)
      @future = Concurrent::Future.execute(executor: AsyncPartial.executor, &block)
    end

    def html_safe?
      true
    end

    def to_s
      self
    end

    def value
      @future.value!
    end
  end

  module ArrayBuffer
    attr_accessor :buffer_values

    def initialize(*)
      super
      @buffer_values = []
    end

    def <<(value)
      @buffer_values << [value, :<<] unless value.nil?
      self
    end
    alias :append= :<<

    def safe_concat(value)
      raise ActiveSupport::SafeBuffer::SafeConcatError unless html_safe?
      @buffer_values << [value, :safe_concat] unless value.nil?
      self
    end
    alias :safe_append= :safe_concat

    def safe_expr_append=(val)
      @buffer_values << [val, :safe_expr_append] unless val.nil?
      self
    end

    def to_s
      result = @buffer_values.each_with_object(ActiveSupport::SafeBuffer.new) do |(v, meth), buf|
        if meth == :<<
          if AsyncPartial::AsyncResult === v
            buf << v.value
          else
            buf << v.to_s
          end
        else
          if AsyncPartial::AsyncResult === v
            buf.safe_concat(v.value)
          else
            buf.safe_concat(v.to_s)
          end
        end
      end
      result.to_s
    end
  end
end
