# -*- coding: utf-8; -*-
require 'spec_helper'

describe TDiary::Style::GfmDiary do
	before do
		@diary = TDiary::Style::GfmDiary.new(Time.at( 1041346800 ), "TITLE", "")
	end

	describe '#append' do
		before do
			@source = <<-'EOF'
# subTitle
honbun

## subTitleH4
honbun

```
# comment in code block
```

			EOF
			@diary.append(@source)
		end

		context 'HTML' do
			before do
				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p>honbun</p>
<h4>subTitleH4</h4>
<p>honbun</p>
<pre><code># comment in code block
</code></pre>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end

		context 'CHTML' do
			before do
				@html = <<-'EOF'
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p>honbun</p>
<h4>subTitleH4</h4>
<p>honbun</p>
<pre><code># comment in code block
</code></pre>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
				EOF
			end
			it { expect(@diary.to_html({}, :CHTML)).to eq @html }
		end

		context 'to_src' do
			it { expect(@diary.to_src).to eq @source }
		end
	end

	describe '#replace' do
		before do
			source = <<-'EOF'
# subTitle
honbun

## subTitleH4
honbun

			EOF
			@diary.append(source)

			replaced = <<-'EOF'
# replaceTitle
replace

## replaceTitleH4
replace

			EOF
			@diary.replace(Time.at( 1041346800 ), "TITLE", replaced)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "replaceTitle" ) %></h3>
<p>replace</p>
<h4>replaceTitleH4</h4>
<p>replace</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'autolink' do
		before do
			source = <<-EOF
# subTitle

 * http://www.google.com

[google](https://www.google.com)

http://www.google.com
         EOF
			@diary.append(source)
			@html = <<-EOF
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<ul>
<li><a href="http://www.google.com">http://www.google.com</a></li>
</ul>
<p><a href="https://www.google.com">google</a></p>
<p><a href="http://www.google.com">http://www.google.com</a></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
         EOF
		end

		it { expect(@diary.to_html).to eq @html }
	end

  describe 'auto imagelink' do
		before do
			source = <<-EOF
# subTitle

![](http://www.google.com/logo.jpg)

![google](http://www.google.com/logo.jpg)
         EOF
			@diary.append(source)
			@html = <<-EOF
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><img src="http://www.google.com/logo.jpg" alt="" /></p>
<p><img src="http://www.google.com/logo.jpg" alt="google" /></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
         EOF
		end

		it { expect(@diary.to_html).to eq @html }

  end

  describe 'auto imagelink' do
		before do
			source = <<-EOF
# subTitle

<a href="http://www.exaple.com" target="_blank">Anchor</a>
         EOF
			@diary.append(source)
			@html = <<-EOF
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><a href="http://www.exaple.com" target="_blank">Anchor</a></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
         EOF
		end

		it { expect(@diary.to_html).to eq @html }

  end

	describe 'url syntax with code blocks' do
		before do
			source = <<-'EOF'
# subTitle

```ruby
@foo
```

http://example.com is example.com

			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<pre><code class="language-ruby">@foo
</code></pre>
<p><a href="http://example.com">http://example.com</a> is example.com</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'ignored url syntax with markdown anchor' do
		before do
			source = <<-'EOF'
# subTitle

[example](http://example.com) is example.com

			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><a href="http://example.com">example</a> is example.com</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'plugin syntax' do
		before do
			source = <<-'EOF'
# subTitle
{{plugin 'val'}}

{{plugin "val", 'val'}}

{{plugin <<EOS, 'val'
valval
valval
vaoooo
EOS
}}

			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><%=plugin 'val'%></p>
<p><%=plugin "val", 'val'%></p>
<p><%=plugin <<EOS, 'val'
valval
valval
vaoooo
EOS
%></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'plugin syntax with url args' do
		before do
			source = <<-'EOF'
# subTitle
{{plugin 'http://www.example.com/foo.html', "https://www.example.com/bar.html"}}

			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><%=plugin 'http://www.example.com/foo.html', "https://www.example.com/bar.html"%></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'link to my plugin' do
		before do
			source = <<-'EOF'
# subTitle

[](20120101p01)

[Link](20120101p01)

			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><%=my "20120101p01", "20120101p01" %></p>
<p><%=my "20120101p01", "Link" %></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'code highlighting' do
		before do
			source = <<-'EOF'
# subTitle

```ruby
 def class
   @foo = 'bar'
 end
 ```
			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<pre><code class="language-ruby"> def class
   @foo = 'bar'
 end
</code></pre>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'ignore emphasis' do
		before do
			source = <<-'EOF'
# subTitle

@a_matsuda is amatsuda

{{isbn_left_image ''}}
			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p>@<a class="tweet-url username" href="https://twitter.com/a_matsuda" rel="nofollow">a_matsuda</a> is amatsuda</p>
<p><%=isbn_left_image ''%></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	context 'twitter username' do
		describe 'in plain context' do
			before do
				source = <<-'EOF'
# subTitle

@a_matsuda is amatsuda
				EOF
				@diary.append(source)

				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p>@<a class="tweet-url username" href="https://twitter.com/a_matsuda" rel="nofollow">a_matsuda</a> is amatsuda</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end

		describe 'with <pre>' do
			before do
				source = <<-'EOF'
# subTitle

    p :some_code

@a_matsuda is amatsuda
				EOF
				@diary.append(source)

				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<pre><code>p :some_code
</code></pre>
<p>@a_matsuda is amatsuda</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end

		describe 'with <code>' do
			before do
				source = <<-'EOF'
# subTitle

`:some_code`

@a_matsuda is amatsuda
				EOF
				@diary.append(source)

				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><code>:some_code</code></p>
<p>@a_matsuda is amatsuda</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end
  end

	context 'emoji' do
		describe 'in plain context' do
			before do
				source = <<-'EOF'
# subTitle

:sushi: は美味しい
				EOF
				@diary.append(source)

				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><img src='//www.webpagefx.com/tools/emoji-cheat-sheet/graphics/emojis/sushi.png' width='20' height='20' title='sushi' alt='sushi' class='emoji' /> は美味しい</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end

		describe 'in (multiline) <pre>' do
			before do
				source = <<-'EOF'
# subTitle

```
:sushi: は
美味しい
```
				EOF
				@diary.append(source)

				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<pre><code>:sushi: は
美味しい
</code></pre>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end

		describe 'in <code>' do
			before do
				source = <<-'EOF'
# subTitle

`:sushi:` は美味しい
				EOF
				@diary.append(source)

				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><code>:sushi:</code> は美味しい</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end

		describe 'in <code> (with attribute)' do
			before do
				source = <<-'EOF'
# subTitle

<code class="foo">:sushi:</code> は美味しい
				EOF
				@diary.append(source)

				@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p><code class="foo">:sushi:</code> は美味しい</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
				EOF
			end
			it { expect(@diary.to_html).to eq @html }
		end
	end

	describe 'do not modify original string' do
		before do
			@orig_source = <<-'EOF'
# subTitle

{{fn 'テスト'}}"
			EOF
			@source = @orig_source.dup
			@diary.append(@source)
			@diary.to_html

			@section = nil
			@diary.each_section{|x| @section = x}
		end
		it { expect(@section.body).to eq("\n"+@orig_source.lines.to_a.last+"\n") }
	end

	describe 'stashes in pre, code, plugin' do
		before do
			source = <<-'EOF'
# subTitle

```
ruby -e "puts \"hello, world.\""
```

`ruby -e "puts \"hello, world.\""`

{{plugin "\0", "\1", "\2"}}
			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<pre><code>ruby -e &quot;puts \&quot;hello, world.\&quot;&quot;
</code></pre>
<p><code>ruby -e &quot;puts \&quot;hello, world.\&quot;&quot;</code></p>
<p><%=plugin "\0", "\1", "\2"%></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'plugin syntax in pre, code block' do
		before do
			source = <<-'EOF'
# subTitle

Get IP Address of Docker Container:

```
% docker inspect -f "{{.NetworkSettings.IPAddress}}  {{.Config.Hostname}}  # Name:{{.Name}}" `docker ps -q`
```

NOTE: `{{.NetworkSettings.IPAddress}}` is golang template.
			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p>Get IP Address of Docker Container:</p>
<pre><code>% docker inspect -f &quot;{{.NetworkSettings.IPAddress}}  {{.Config.Hostname}}  # Name:{{.Name}}&quot; `docker ps -q`
</code></pre>
<p>NOTE: <code>{{.NetworkSettings.IPAddress}}</code> is golang template.</p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end

	describe 'youtube link with @' do
		before do
			source = <<-'EOF'
# subTitle

This is a link to youtube.com/@username
Another one: https://www.youtube.com/@anotheruser

This is a normal mention @twitteruser.
A link with @ in path http://example.com/path/@foo/bar
			EOF
			@diary.append(source)

			@html = <<-'EOF'
<div class="section">
<%=section_enter_proc( Time.at( 1041346800 ) )%>
<h3><%= subtitle_proc( Time.at( 1041346800 ), "subTitle" ) %></h3>
<p>This is a link to <a href="https://youtube.com/@username">youtube.com/@username</a>
Another one: <a href="https://www.youtube.com/@anotheruser">https://www.youtube.com/@anotheruser</a></p>
<p>This is a normal mention @<a class="tweet-url username" href="https://twitter.com/twitteruser" rel="nofollow">twitteruser</a>.
A link with @ in path <a href="http://example.com/path/@foo/bar">http://example.com/path/@foo/bar</a></p>
<%=section_leave_proc( Time.at( 1041346800 ) )%>
</div>
			EOF
		end
		it { expect(@diary.to_html).to eq @html }
	end
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# End:
