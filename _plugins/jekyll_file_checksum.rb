module Jekyll

    class FileChecksumTag < Liquid::Block

      def initialize(tag_name, markup, options)
        @tag = markup
        super
      end

      def render(context)
        contents = super
        contents = contents.strip
        dest = context.registers[:site].dest
        file = open(File.join(dest, contents))
        get_checksum(file)
      end

      def get_checksum(file)
        require 'digest'
        return Digest::MD5.hexdigest(file.read)
      end
    end

end

Liquid::Template.register_tag('checksum', Jekyll::FileChecksumTag)
