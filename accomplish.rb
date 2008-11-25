#!/usr/bin/env ruby
# Copyright (c) 2007-2008 Eivind Uggedal <eu@redflavor.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
#
# Accomplish - As minimal a task list as possible
#
# Usage:
#
#   1. vi tasks
#   2. Prefix tasks with !, *, or ? based on importance. Double linebreaks
#      between tasks:
#
#      ! Superduper important task
#        due in the morning.
#
#      ? Not sure if I want to do this.
#
#      * This has to be done, eventually.
#
#   3. gem install BlueCloth rubypants haml
#   4. ./accomplish.rb
#   5. Hook up public/ to a web server like nginx

%w(rubygems bluecloth rubypants haml sass stringio time).each { |lib| require lib }

TITLE      = 'Research Task List'
AUTHOR     = {:name => 'Eivind Uggedal',
              :email => 'eu@redflavor.com',
              :url => 'http://redflavor.com'}
PRIORITIES = [{'!' => :important }, {'*' => :normal}, {'?' => :optional}]
PUBLIC = File.join(File.dirname(__FILE__), 'public')

# Monkey patch for not forming paragraphs.
BlueCloth.module_eval do
  def form_paragraphs( str, rs )
    grafs = str.sub( /\A\n+/, '' ).sub( /\n+\z/, '' ).split( /\n{2,}/ )
    grafs.collect { |graf| apply_span_transforms(graf, rs) }.join( "\n\n" )
  end
end

# Accessors for getting the first key and value of a hash
Hash.module_eval do
  def k; self.keys.first; end
  def v; self.values.first; end
end

# Stolen from Sinatra
def templates
  templates = {}

  eof = IO.read(caller.first.split(':').first).split('__FILE__').last
  data = StringIO.new(eof)

  current_template = nil
  data.each do |line|
    if line =~ /^##\s?(.*)/
      current_template = $1.to_sym
      templates[current_template] = ''
    elsif current_template
      templates[current_template] << line
    end
  end
  templates
end

# Returns an array of task items.
def tasklist(file=File.expand_path('../tasks', __FILE__))
  return [] unless File.exists? file
  prioritize File.read(file).split("\n\n")
end

# Returns a hash of tasks of different prioritization
def prioritize(tasks)
  prioritized = {}
  tasks.each do |task|
    PRIORITIES.each do |p|
      prioritized[p.k] ||= []
      prioritized[p.k] << task.strip[2..-1] if task.strip[0..0] == p.k
    end
  end
  prioritized
end

# Parses text from mardown to nice html.
def htmlify(text)
  RubyPants.new(BlueCloth.new(text).to_html).to_html
end

def write_file(fname, data, root=PUBLIC)
  File.open(File.join(root, fname), 'w') { |f| f.puts data }
end

def clean_public
  FileUtils.rm_r PUBLIC if File.exists? PUBLIC
  FileUtils.mkdir_p PUBLIC
end

def generate_style
  style = Sass::Engine.new(templates[:style]).render
  write_file('style.css', style)
end

def render_haml(template, bind=binding)
  Haml::Engine.new(templates[template], {:format => :html4}).render(bind)
end

def generate_index
  @tasks = tasklist
  index = render_haml(:index, binding)
  write_file('index.html', index)
end

if __FILE__ == $0
  clean_public
  generate_style
  generate_index
end

__END__

## index
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
%html
  %head
    %title= TITLE
    %meta{'http-equiv' => 'Content-Type', :content => 'text/html;charset=utf-8'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/style.css'}
  %body

    %h1= TITLE
    %ol#tasklist
      - PRIORITIES.each do |pri|
        - @tasks[pri.k].each do |task|
          %li{:class => pri.v}= htmlify(task)
    %h2 Legend
    %ul
      - PRIORITIES.each do |pri|
        %li{:class => pri.v}= pri.v
    %address.vcard
      %a.url.fn{ :href => AUTHOR[:url] }= AUTHOR[:name]
      %a.email{ :href => "mailto:#{AUTHOR[:email]}" }= AUTHOR[:email]

## style
body
  :font-size 90%
  :font-family 'DejaVu Sans', 'Bitstream Vera Sans', Verdana, sans-serif
  :line-height 1.5
  :padding 0 5em 0 5em
#tasklist
  :-moz-column-width 28em
  :-moz-column-gap 1.5em
  :-webkit-column-width 28em
  :-webkit-column-gap 1.5em
ol li
  :margin 0 1em 0.3em 0
  :padding 0.1em 0.1em 0.1em 0.4em
ul
  :list-style-type none
  :padding 0
  li
    :display inline
a
  :background #ffb
  :color #000
h1, h2
  :font-family Georgia, 'DejaVu Serif', 'Bitstream Vera Serif', serif
  :font-weight normal
address
  :font-family monospace
  :margin 2em 0 0 0
.important
  :background #fdb
.normal
  :background #fec
.optional
  :background #ffd
