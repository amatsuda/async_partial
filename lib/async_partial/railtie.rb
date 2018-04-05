# frozen_string_literal: true

module AsyncPartial
  class Railtie < ::Rails::Railtie
    initializer 'async_partial' do
      ActiveSupport.on_load :action_view do
        ActionView::PartialRenderer.prepend AsyncPartial::Renderer
        ActionView::OutputBuffer.prepend AsyncPartial::ArrayBuffer

        begin
          require 'action_view/template/handlers/erb/erubi'
          require_relative 'handlers/erubi'

          ActionView::Template::Handlers::ERB.erb_implementation = ActionView::Template::Handlers::ERB::ThreadSafeErubi
        rescue LoadError
        end

        if Gem.loaded_specs.detect {|g| g[0] == 'slim'}
          require 'temple/generators/rails_output_buffer'
          require_relative 'handlers/slim'

          Temple::Templates::Rails(Slim::Engine, register_as: :slim, generator: Temple::Generators::ThreadedRailsOutputBuffer, disable_capture: true, streaming: true)
        end
      end
    end
  end
end
