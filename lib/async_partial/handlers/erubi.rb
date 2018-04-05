# frozen_string_literal: true

module ActionView
  class Template
    module Handlers
      class ERB
        class ThreadSafeErubi < Erubi
          def initialize(input, properties = {})
            @newline_pending = 0

            # Dup properties so that we don't modify argument
            properties = Hash[properties]
            properties[:preamble]   = "output_buffer = ActionView::OutputBuffer.new;"
            properties[:postamble]  = "output_buffer.to_s"
            properties[:bufvar]     = "output_buffer"
            properties[:escapefunc] = ""

            # Call ::Erubi::Engine#initializer
            method(__method__).super_method.super_method.call input, properties
          end

          private

          eval Erubi.instance_method(:add_text).source.gsub('@output_buffer', '#{@bufvar}')
          eval Erubi.instance_method(:add_expression).source.gsub('@output_buffer', '#{@bufvar}')
          eval Erubi.instance_method(:flush_newline_if_pending).source.gsub('@output_buffer', '#{@bufvar}')
        end
      end
    end
  end
end
