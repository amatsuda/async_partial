# frozen_string_literal: true

module AsyncPartial
  class Railtie < ::Rails::Railtie
    initializer 'async_partial' do
      ActiveSupport.on_load :action_view do
        ActionView::PartialRenderer.prepend AsyncPartial::Renderer
        ActionView::OutputBuffer.prepend AsyncPartial::ArrayBuffer
        ActionView::Base.prepend AsyncPartial::CaptureHelper
        ActionView::Template.prepend AsyncPartial::PerThreadBufferStack
        ActionView::Template.prepend AsyncPartial::TemplateRenderer

        begin
          require 'action_view/template/handlers/erb/erubi'
          require_relative 'handlers/erubi'

          ActionView::Template::Handlers::ERB.erb_implementation = ActionView::Template::Handlers::ERB::ThreadSafeErubi
        rescue LoadError
          begin
            require 'action_view/template/handlers/erb'
            require_relative 'handlers/erubis'

            ActionView::Template::Handlers::ERB.erb_implementation = ActionView::Template::Handlers::ERB::ThreadSafeErubis
          rescue LoadError
            raise 'No Erubi nor Erubis found.'
          end
        end
      end
    end

    if Gem.loaded_specs.detect {|g| g[0] == 'haml'}
      initializer 'async_partial_haml', after: :haml do
        require 'haml/buffer'
        require_relative 'handlers/haml'
      end
    end

    if Gem.loaded_specs.detect {|g| g[0] == 'slim'}
      initializer 'async_partial_slim', after: 'slim_rails.configure_template_digestor' do
        require 'temple'
        require 'temple/generators/rails_output_buffer'
        require_relative 'handlers/slim'

        Temple::Templates::Rails(Slim::Engine, register_as: :slim, generator: Temple::Generators::ThreadedRailsOutputBuffer, disable_capture: true, streaming: true)
      end
    end

    if Gem.loaded_specs.detect {|g| g[0] == 'faml'}
      initializer 'async_partial_faml', after: :faml do
        require 'temple'
        require 'temple/generators/rails_output_buffer'
        require_relative 'handlers/slim'

        ActionView::Template.register_template_handler(:haml, ->(template) { Faml::Engine.new(use_html_safe: true, generator: Temple::Generators::ThreadedRailsOutputBuffer, filename: template.identifier).call(template.source) })
        ActionView::Template.register_template_handler(:faml, ->(template) { Faml::Engine.new(use_html_safe: true, generator: Temple::Generators::ThreadedRailsOutputBuffer, filename: template.identifier).call(template.source) })
      end
    end
  end
end
