# frozen_string_literal: true

module AsyncPartial
  class HamlArrayBuffer < Array
    def html_safe
      map {|v| AsyncPartial::AsyncResult === v ? v.value : v}.join.html_safe
    end
  end

  module HamlArrayBufferizer
    def initialize(*)
      super;
      @buffer = AsyncPartial::HamlArrayBuffer.new
    end
  end

  Haml::Buffer.prepend HamlArrayBufferizer
end