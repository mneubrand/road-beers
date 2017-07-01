# Jekyll GalleryTag
# 
# Automatically creates thumbnails for a directory of images.
# Adds a "gallery" Liquid tag
# 
# Author: Matt Harzewski
# Copyright: Copyright 2013 Matt Harzewski
# License: GPLv2 or later
# Version: 1.1.0


require "RMagick"

module Jekyll


	class GalleryTag < Liquid::Block


	 	def initialize(tag_name, markup, tokens)
			super
			@gallery_name = markup
		end


		def render(context)
		    contents = super

			@config = context.registers[:site].config['gallerytag']
			columns = (@config['columns'] != nil) ? @config['columns'] : 4

			images = gallery_images(contents)

			images_html = ""
			images.each_with_index do |image, key|
			    lqip = image['thumbnail'].to_s().sub(/\.jpg/, '@lqip.jpg')
			    retina = image['thumbnail'].to_s().sub(/\.jpg/, '@2x.jpg')

				images_html << "<div class=\"gallery-item\">"
				images_html << "<a class=\"gallery-link\" data-lightbox=\"#{@gallery_name}\" href=\"#{image['url']}\" title=\"#{image['caption']}\">"
				images_html << "<img src=\"#{lqip}\" class=\"blur\" />"
				images_html << "<img data-srcset=\"#{image['thumbnail']} 300w, #{retina} 600w\" class=\"lazyload\" />"
				images_html << "<noscript><img src=\"#{image['thumbnail']}\" /></noscript>"
				images_html << "</a>"
				images_html << "<div class=\"gallery-caption\">#{image['caption']}</div>"
				images_html << "</div>"
			end
			gallery_html = "<div class=\"gallery\">\n#{images_html}\n</div><div class=\"clear\"></div>\n"

			return gallery_html

		end


		def gallery_images(contents)
			input_data = block_contents(contents)
			gallery_data = []
			input_data.each do |item|
				hsh = {
					"url" => "#{@config['url']}/#{item[0]}",
					"thumbnail" => GalleryThumbnail.new(item[0], @config), #this should be url to a generated thumbnail, eventually
					"caption" => item[1]
				}
				gallery_data.push(hsh)
			end
			return gallery_data
		end


		def block_contents(contents)
			text = contents
			lines = text.split(/\n/).map {|x| x.strip }.reject {|x| x.empty? }
			lines = lines.map { |line|
				line.split(/\s*::\s*/).map(&:strip)
			}
			return lines
		end


	end



	class GalleryThumbnail


	 	def initialize(image_filename, config)
	 		@img_filename = image_filename
	 		@config = config
	 	end


	 	def to_s
	 		get_url
	 	end


	 	def get_url
	 		filename = File.path(@img_filename).sub(File.extname(@img_filename), "-thumb#{File.extname(@img_filename)}")
	 		"#{@config['url']}/#{filename}"
	 	end


	end

    # This part is copied from https://github.com/kinnetica/jekyll-plugins
	# Without it, generation does fail. --dmytro
	# Recover from strange exception when starting server without --auto
	class GalleryFile < StaticFile
		def write(dest)
		end
	end


	class ThumbGenerator < Jekyll::Generator


	 	def generate(site)

	 		@config = site.config['gallerytag']
	 		@gallery_dir  = File.expand_path(@config['dir'])
	 		@gallery_dest = File.expand_path(File.join(site.dest, @config['dir']))

	 		thumbify(files_to_resize(site))

	 	end


	 	def files_to_resize(site)

	 		to_resize = []

	 		Dir.glob(File.join(@gallery_dir, "**", "*.{png,jpg,jpeg,gif}")).each do |file|
	 			if !File.basename(file).include? "-thumb"
	 				name = File.basename(file).sub(File.extname(file), "-thumb#{File.extname(file)}")
	 				thumbname = File.join(@gallery_dest, File.basename(File.dirname(file)), name)
	 				retina = thumbname.sub(/\.jpg/, '@2x.jpg')
	 				lqip = thumbname.sub(/\.jpg/, '@lqip.jpg')

	 				name_lqip = File.basename(file).sub(File.extname(file), "@lqip#{File.extname(file)}")
	 				lqip_full = File.join(@gallery_dest, File.basename(File.dirname(file)), name_lqip)

	                # Keep the thumb files from being cleaned by Jekyll
	                dir = File.join(@config['dir'], File.basename(File.dirname(file)))
	                site.static_files << GalleryFile.new(site, site.source, dir, name )
	                site.static_files << GalleryFile.new(site, site.source, dir, name.sub(/\.jpg/, '@2x.jpg') )
	                site.static_files << GalleryFile.new(site, site.source, dir, name.sub(/\.jpg/, '@lqip.jpg') )
	                site.static_files << GalleryFile.new(site, site.source, dir, name_lqip )

	 				if !File.exists?(thumbname)
	 				    to_resize.push({ "file" => file, "thumbname" => thumbname })
	 				elsif !File.exists?(retina)
	 				    to_resize.push({ "file" => file, "thumbname" => thumbname })
                    elsif !File.exists?(lqip)
                        to_resize.push({ "file" => file, "thumbname" => thumbname })
                     elsif !File.exists?(lqip_full)
                        to_resize.push({ "file" => file, "thumbname" => thumbname })
	 				end
	 			end
	 		end

	 		return to_resize

	 	end


	 	def thumbify(items)
	 		if items.count > 0
		 		items.each do |item|
		 		    if !File.exists?(item['thumbname'])
                        dir = File.dirname(item['thumbname'])
                        if !File.exists?(dir)
                            FileUtils.mkdir_p(dir)
                        end

                        img = Magick::Image.read(item['file']).first
                        thumb = img.resize_to_fill!(@config['thumb_width'], @config['thumb_height'])
                        thumb.write(item['thumbname'])
                        thumb.destroy!
                    end

                    retina = item['thumbname'].sub(/\.jpg/, '@2x.jpg');
                    if !File.exists?(retina)
                        img = Magick::Image.read(item['file']).first
                        thumb_retina = img.resize_to_fill!(@config['thumb_width'] * 2, @config['thumb_height'] * 2)
                        thumb_retina.write(retina)
                        thumb_retina.destroy!
                    end

                    lqip = item['thumbname'].sub(/\.jpg/, '@lqip.jpg');
                    if !File.exists?(lqip)
                        img = Magick::Image.read(item['file']).first
                        thumb_lqip = img.resize_to_fill!(@config['thumb_width'] * 0.2, @config['thumb_height'] * 0.2)
                        thumb_lqip.write(lqip)
                        thumb_lqip.destroy!
                    end

                    lqip_full = item['thumbname'].sub(/-thumb\.jpg/, '@lqip.jpg');
                    if !File.exists?(lqip_full)
                        img = Magick::Image.read(item['file']).first
                        thumb_lqip = img.resize(0.1)
                        thumb_lqip.write(lqip_full)
                        thumb_lqip.destroy!
                    end
		 		end
	 		end
	 	end


	end



end

Liquid::Template.register_tag('gallery', Jekyll::GalleryTag)
