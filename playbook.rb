# encoding: utf-8
require 'nokogiri'

if !File.size?('home.html')
  `curl http://playbook.thoughtbot.com/ > home.html`
end
doc = Nokogiri::HTML.parse(File.open('home.html', 'r:utf-8'))

puts "Parsing table of contents"

toc = []
doc.css('section#chapters a').each do |a|
  text = a.inner_text
  if a.parent.name == 'h2'
    toc << {:section => text, :href => a[:href]}
  elsif a.parent.name == 'p'
    toc << {:page => text, :href => a[:href]}
  end
end

toc_doc = Nokogiri::HTML(File.read("home.html")).at("section#chapters")
toc_html = toc_doc.serialize.gsub(/ id=[^>]*/, '')

puts "Loading pages"

big_html = toc.inject([toc_html]) do |memo, x|
  puts x[:href]
  html = `curl -sL 'http://playbook.thoughtbot.com#{x[:href]}'`
  doc = Nokogiri::HTML(html)
 
  memo << "<div><a name='#{x[:href].sub('/', '').gsub(/\W/, '_')}'></a></div>"
  memo << doc.at('section#content').inner_html
  memo
end

raw = big_html.join("\n")

File.open("raw.html", 'w') {|f| f.puts raw}

puts "Writing aggregated html fragments to raw.html"

raw = File.read("raw.html")

html = <<END
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
</head>
<body>
#{ raw }
</body>
</html>
END

doc = Nokogiri::HTML(html)

print "Linking relative hrefs to anchors"

doc.search('a').each do |a|
  href = a[:href]
  if href =~ /^\//
    print '.'
    new = "<a href='##{href.sub('/', '').gsub(/\W/, '_')}'>#{a.inner_text}</a>"
    a.swap(new)
  end
end
puts 
puts "Writing result out to playbook.html"
File.open("playbook.html", 'w') {|f| f.puts doc.serialize}

