require "mimemagic"

module ImageEncodeCache
  @@cached_base64_codes = Hash.new

  def cached_base64_codes
    @@cached_base64_codes
  end

  def cached_base64_codes= val
    @@cached_base64_codes = val
  end
end

module Jekyll

    class ImageEncodeTag < Liquid::Block
      include ImageEncodeCache

      def initialize(tag_name, markup, options)
        @tag = markup
        super
      end

      def render(context)
        contents = super
        contents = contents.strip
        dest = context.registers[:site].dest
        file = open(File.join(dest, contents))
        encode_image(file)
      end

      def encode_image(file)
        require 'open-uri'
        require 'base64'

        encoded_image = ''
        image_handle = open(file)

        if self.cached_base64_codes.has_key? file
          encoded_image = self.cached_base64_codes[file]
        else
          encoded_image = Base64.strict_encode64(image_handle.read)
          self.cached_base64_codes.merge!(file => encoded_image)
        end

        data_type = MimeMagic.by_magic(image_handle)
        image_handle.close

        "data:#{data_type};base64,#{encoded_image}"
      end
    end

end

Liquid::Template.register_tag('base64', Jekyll::ImageEncodeTag)
