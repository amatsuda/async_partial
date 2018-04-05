# frozen_string_literal: true

module AsyncPartial
  class Railtie < ::Rails::Railtie
    initializer 'async_partial' do
      ActiveSupport.on_load :action_view do
        ActionView::PartialRenderer.prepend AsyncPartial::Renderer
        ActionView::OutputBuffer.prepend AsyncPartial::ArrayBuffer
      end
    end
  end
end
