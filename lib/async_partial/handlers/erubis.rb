# frozen_string_literal: true

module ActionView
  class Template
    module Handlers
      class ERB
        class ThreadSafeErubis < Erubis
          eval Erubis.instance_method(:add_preamble).source.gsub('@output_buffer', 'output_buffer')
          eval Erubis.instance_method(:add_text).source.gsub('@output_buffer', 'output_buffer')
          eval Erubis.instance_method(:add_expr).source.gsub('@output_buffer', 'output_buffer')
          eval Erubis.instance_method(:add_expr_literal).source.gsub('@output_buffer', 'output_buffer')
          eval Erubis.instance_method(:add_expr_escaped).source.gsub('@output_buffer', 'output_buffer')
          eval Erubis.instance_method(:add_postamble).source.gsub('@output_buffer', 'output_buffer')
          eval Erubis.instance_method(:flush_newline_if_pending).source.gsub('@output_buffer', 'output_buffer')
        end
      end
    end
  end
end
