# frozen_string_literal: true

module Temple
  module Generators
    # Implements a threaded rails output buffer.
    #
    #   output_buffer = ActionView::OutputBuffer.new
    #   output_buffer.safe_concat "static"
    #   output_buffer.safe_concat dynamic
    #   output_buffer.to_s
    class ThreadedRailsOutputBuffer < RailsOutputBuffer
      set_options buffer_class: 'ActionView::OutputBuffer', buffer: 'output_buffer'

      def on_dynamic(code)
        concat(code)
      end

      def return_buffer
        "#{buffer}.to_s"
      end
    end
  end
end
