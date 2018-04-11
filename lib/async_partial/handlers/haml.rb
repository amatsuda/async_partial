# frozen_string_literal: true

module AsyncPartial
  class HamlArrayBuffer < Array
    def html_safe
      map {|v| AsyncPartial::AsyncResult === v ? v.value : v}.join.html_safe
    end

    def rstrip!
      if last.frozen?
        if (stripped = last.dup.rstrip!)
          self[-1] = stripped
        end
      else
        last.rstrip!
      end
      if last.blank?
        last.pop
        rstrip!
      end
      self
    end
  end

  module HamlArrayBufferizer
    def initialize(*)
      super
      @buffer = AsyncPartial::HamlArrayBuffer.new
    end
  end

  Haml::Buffer.prepend HamlArrayBufferizer
end
