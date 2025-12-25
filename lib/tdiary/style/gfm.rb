# -*- coding: utf-8; -*-

require 'commonmarker'
require 'twitter-text'

module TDiary
	module Style
		class GfmSection
			def initialize(fragment, author = nil)
				@author = author
				@subtitle, @body = fragment.split(/\n/, 2)
				@subtitle.sub!(/^\#\s*/,'')
				@body ||= ''

				@categories = get_categories
				@stripped_subtitle = strip_subtitle

				@subtitle_to_html = @subtitle ? to_html('# ' + @subtitle).gsub(/\A<h\d>|<\/h\d>\z/io, '') : nil
				@stripped_subtitle_to_html = @stripped_subtitle ? to_html('# ' + @stripped_subtitle).gsub(/\A<h\d>|<\/h\d>\z/io, '') : nil
				@body_to_html = to_html(@body)
			end

			def subtitle=(subtitle)
				@subtitle = (subtitle || '').sub(/^# /,"\##{categories_to_string} ")
				@strip_subtitle = strip_subtitle
			end

			def categories=(categories)
				@subtitle = "#{categories_to_string} " + (strip_subtitle || '')
				@strip_subtitle = strip_subtitle
			end

			def to_src
				r = ''
				r << "\# #{@subtitle}\n" if @subtitle
				r << @body
			end

			def do_html4(date, idx, opt)
				subtitle = to_html('# ' + @subtitle)
				subtitle.sub!( %r!<h3>(.+?)</h3>!m ) do
					"<h3><%= subtitle_proc( Time.at( #{date.to_i} ), #{$1.dump.gsub( /%/, '\\\\045' )} ) %></h3>"
				end
				if opt['multi_user'] and @author then
					subtitle.sub!(/<\/h3>/,%Q|[#{@author}]</h3>|)
				end
				r = subtitle
				r << @body_to_html
			end

			private

			def to_html(string)
				r = string.dup

				# 1. Stash plugin calls
				plugin_stashes = []
				plugin_blocks, replaced_r = extract_plugin_blocks_and_replace(r)
				plugin_blocks.each do |plugin_block|
					# Convert `{{ }}' to erb tags
					plugin_stashes.push(["{{#{plugin_block}}}", "<%=#{plugin_block}%>"])
				end
				r = replaced_r

				# 2. Apply markdown conversion
				r = Commonmarker.to_html(r,
					options: {
						render: { unsafe: true },
						extension: { header_ids: nil, tagfilter: false }
					}
				)

				# 3. Stash <pre>, <code>, <iframe> and <script> tags
				pre_tag_stashes = []
				r.gsub!(/<pre(.*?)<\/pre>/m) do |matched|
					pre_tag_stashes.push(matched)
					"@@tdiary_style_gfm_pre_tag#{pre_tag_stashes.length - 1}@@"
				end

				code_tag_stashes = []
				r.gsub!(/<code(.*?)<\/code>/m) do |matched|
					code_tag_stashes.push(matched)
					"@@tdiary_style_gfm_code_tag#{code_tag_stashes.length - 1}@@"
				end

				iframe_tag_stashes = []
				r.gsub!(/<iframe(.*?)<\/iframe>/m) do |matched|
					iframe_tag_stashes.push(matched)
					"@@tdiary_style_gfm_iframe_tag#{iframe_tag_stashes.length - 1}@@"
				end

				script_tag_stashes = []
				r.gsub!(/<script(.*?)<\/script>/m) do |matched|
					script_tag_stashes.push(matched)
					"@@tdiary_style_gfm_script_tag#{script_tag_stashes.length - 1}@@"
				end

				# 4. Convert miscellaneous
				if pre_tag_stashes.none? && code_tag_stashes.none?
					# STAGE 1: Stash all existing <a> tags from CommonMarker output
					original_a_tag_stashes = []
					r.gsub!(/(<a\s[^>]*href=[^>]*>.*?<\/a>)/im) do |match|
						original_a_tag_stashes.push(match)
						"@@TDIARY_GFM_A_TAG_#{original_a_tag_stashes.length - 1}@@"
					end

					# STAGE 2: Protect YouTube @-URLs that might still be plain text
					youtube_link_data_for_twitter_text_protection = []
					r.gsub!(/((?:https?:\/\/)?(?:www\.)?youtube\.com\/@([a-zA-Z0-9_.-]+))/) do |match|
						original_text = $1
						placeholder = "@@YT_LINK_PROTECT_#{youtube_link_data_for_twitter_text_protection.length}@@"
						youtube_link_data_for_twitter_text_protection << { placeholder: placeholder, original_text: original_text }
						placeholder
					end

					# STAGE 3: Apply Twitter's autolinker for @mentions and lists.
					r = Twitter::TwitterText::Autolink.auto_link_usernames_or_lists(r)

					# STAGE 4: Restore protected YouTube links (as new <a> tags)
					youtube_link_data_for_twitter_text_protection.each do |link_data|
						original_text = link_data[:original_text]
						href = original_text

						if !href.start_with?('http://') && !href.start_with?('https://')
							if href.include?('youtube.com/')
								href = "https://#{href}"
							else
								href = "http://#{href}"
							end
						end

						youtube_html_link = "<a href=\"#{CGI.escapeHTML(href)}\">#{CGI.escapeHTML(original_text)}</a>"
						r.gsub!(link_data[:placeholder], youtube_html_link)
					end

					# STAGE 5: Restore original <a> tags
					original_a_tag_stashes.each.with_index do |tag_content, i|
						r.gsub!("@@TDIARY_GFM_A_TAG_#{i}@@", tag_content)
					end
				end

				r = r.emojify

				# diary anchor
				r.gsub!(/<h(\d)/) { "<h#{$1.to_i + 2}" }
				r.gsub!(/<\/h(\d)/) { "</h#{$1.to_i + 2}" }

				# my syntax
				r.gsub!(/<a href="(\d{4}|\d{6}|\d{8}|\d{8}-\d+)[^\d]*?#?([pct]\d+)?">(.*?)<\/a>/) {
					unless $3.empty?
						%Q|<%=my "#{$1}#{$2}", "#{$3}" %>|
					else
						%Q|<%=my "#{$1}#{$2}", "#{$1}#{$2}" %>|
					end
				}

				# 5. Unstash <pre>, <code>, <iframe> and <script> and plugin call
				pre_tag_stashes.each.with_index do |str, i|
					plugin_stashes.each.with_index do |(p_str, p_erb), j|
						if str["@@tdiary_style_gfm_plugin#{j}@@"]
							str["@@tdiary_style_gfm_plugin#{j}@@"] = CGI.escapeHTML(p_str)
						end
					end
					r["@@tdiary_style_gfm_pre_tag#{i}@@"] = str
				end
				code_tag_stashes.each.with_index do |str, i|
					plugin_stashes.each.with_index do |(p_str, p_erb), j|
						if str["@@tdiary_style_gfm_plugin#{j}@@"]
							str["@@tdiary_style_gfm_plugin#{j}@@"] = CGI.escapeHTML(p_str)
						end
					end
					r["@@tdiary_style_gfm_code_tag#{i}@@"] = str
				end
				iframe_tag_stashes.each.with_index do |str, i|
					plugin_stashes.each.with_index do |(p_str, p_erb), j|
						if str["@@tdiary_style_gfm_plugin#{j}@@"]
							str["@@tdiary_style_gfm_plugin#{j}@@"] = CGI.escapeHTML(p_str)
						end
					end
					r["@@tdiary_style_gfm_iframe_tag#{i}@@"] = str
				end
				script_tag_stashes.each.with_index do |str, i|
					plugin_stashes.each.with_index do |(p_str, p_erb), j|
						if str["@@tdiary_style_gfm_plugin#{j}@@"]
							str["@@tdiary_style_gfm_plugin#{j}@@"] = CGI.escapeHTML(p_str)
						end
					end
					r["@@tdiary_style_gfm_script_tag#{i}@@"] = str
				end
				plugin_stashes.each.with_index do |(str, erb), i|
					if r["@@tdiary_style_gfm_plugin#{i}@@"]
						r["@@tdiary_style_gfm_plugin#{i}@@"] = erb
					end
				end

				r
			end

			def get_categories
				return [] unless @subtitle
				cat = /(\\?\[([^\[]+?)\\?\])+/.match(@subtitle).to_a[0]
				return [] unless cat
				cat.scan(/\\?\[(.*?)\\?\]/).collect do |c|
					c[0].split(/,/)
				end.flatten
			end

			def strip_subtitle
				return nil unless @subtitle
				r = @subtitle.sub(/^((\\?\[[^\[]+?\]\\?)+\s+)?/, '')
				if r.empty?
					nil
				else
					r
				end
			end

			def extract_plugin_blocks_and_replace(text)
				s = StringScanner.new(text)
				blocks = []
				count = 0
				replaced_text = ""
				while chunk = s.scan_until(/\{\{/)
					chunk[-2, 2] = ""
					replaced_text << chunk
					if plugin_str = extract_plugin_block(s)
						replaced_text << "@@tdiary_style_gfm_plugin#{count}@@"
						blocks << plugin_str
						count += 1
					end
				end
				replaced_text << s.rest
				return blocks, replaced_text
			end

			def extract_plugin_block(s)
				pos = s.pos
				buf = ""
				while chunk = s.scan_until(/\}\}/)
					buf << chunk
					buf.chomp!("}}")
					return buf
				end
				s.pos = pos
				nil
			end

		end

		class GfmDiary
			def initialize(date, title, body, modified = Time.now)
				init_diary
				replace( date, title, body )
				@last_modified = modified
			end

			def style
				'GFM'
			end

			def append(body, author = nil)
				in_code_block = false
				section = nil
				body.each_line do |l|
					case l
					when /^\#[^\#]/
						if in_code_block
							section << l
						else
							@sections << GfmSection.new(section, author) if section
							section = l
						end
					when /^```/
						in_code_block = !in_code_block
						section << l
					else
						section = '' unless section
						section << l
					end
				end
				if section
					section << "\n" unless section =~ /\n\n\z/
					@sections << GfmSection.new(section, author)
				end
				@last_modified = Time.now
				self
			end

			def add_section(subtitle, body)
				@sections = GfmSection.new("\# #{subtitle}\n\n#{body}")
				@sections.size
			end
		end
	end
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# End:
