require 'httparty'
require 'nokogiri'
require 'fileutils'

module Ffnpdf
  class Story
    FFN_URL = "http://www.fanfiction.net/"

    attr_accessor :custom_url, :error

    def initialize(story_id)
      @story_id = story_id
    end

    def check_story_id
      unless /^[\d]*$/.match @story_id
        @error = "Story ID is invalid"
        return false
      end
      true
    end

    def check_story
      return false unless check_story_id

      test_pull = HTTParty.get(story_url)
      unless test_pull.code == 200
        @error = "Story does not exist (#{story_url})"
        return false
      end

      true
    end

    def check_story_dir
      return false unless check_story_id
      
      unless File.directory?(@story_id)
        @error = "Story folder does not exist (#{@story_id}/)"
        return false
      end

      unless chapter_mds.count > 0
        @error = "Story folder does not have markdown files (#{@story_id}/)"
        return false
      end

      true
    end

    def chapter_mds
      Dir["#{@story_id}/*"].grep(/.md$/).reject { |x| x == "compiled.md" }.sort
    end

    def story_url
      custom_url ? "#{@custom_url}s/#{@story_id}/" : "#{FFN_URL}s/#{@story_id}/"
    end

    def pull_story
      return unless check_story
      FileUtils.mkdir_p @story_id
      Dir.chdir @story_id
      tempfile = File.new("temp.html", "w")
      pull = HTTParty.get(story_url)
      doc = Nokogiri::HTML(pull.body)
      doc.css(".storytext")[0].children.each do |paragraph|
        if /^<(p|hr|i|b)/.match paragraph.to_s
          tempfile.puts paragraph
        end
      end
      tempfile.close
      parsing = doc.xpath('//div[@style="padding-left:1em;padding-right:1em;padding-top:0.5em;"]')[0].text
      match = /Published: (.{8})/.match parsing
      published = Date.strptime(match[1], "%m-%d-%y").strftime("%d %B %Y")

      template = File.new("xetex.template", "w")
      contents = <<-CONTENTS
% Shamelessly ripped off from https://github.com/karlseguin/the-little-mongodb-book
\\documentclass{book}
\\usepackage{fullpage}
\\usepackage{changepage}
\\usepackage{fontspec,xltxtra,xunicode}
\\defaultfontfeatures{Mapping=tex-text,Scale=MatchLowercase}
\\setmainfont{$mainfont$}
\\setsansfont{$sansfont$}
\\setmonofont{$monofont$}

\\setlength{\\parindent}{0pt}
\\setlength{\\parskip}{12pt plus 2pt minus 1pt}
\\linespread{1.2}


\\usepackage{listings}
\\usepackage[dvipsnames,usenames]{color}

\\definecolor{lightgray}{rgb}{.95,.95,.95}
\\definecolor{darkgray}{rgb}{.4,.4,.4}
\\definecolor{purple}{rgb}{0.65, 0.12, 0.82}

$if(fancy-enums)$
\\usepackage{enumerate}
$endif$
\\setcounter{secnumdepth}{-1}

\\usepackage{hyperref}
\\hypersetup{
    colorlinks=true,%
    citecolor=YellowOrange,%
    filecolor=YellowOrange,%
    linkcolor=YellowOrange,%
    urlcolor=YellowOrange
}

\\usepackage[compact]{titlesec}
\\titlespacing{\\section}{0pt}{*0}{*-2}
\\titlespacing{\\subsection}{0pt}{*0}{*-2}
\\titlespacing{\\subsubsection}{0pt}{*1}{*-2}

\\title{#{doc.xpath("//div/div/b")[0].text}}
\\author{#{doc.xpath("//div/table//a")[0].text}}
\\date{#{published}}
\\begin{document}
$body$
\\end{document}
      CONTENTS
      template.puts(contents)
      template.close

      variables = File.new("variables.txt", "w")
      variables.puts("-V paper=a4paper -V hmargin=3cm -V vmargin=3cm -V mainfont=\"Times New Roman\" -V sansfont=\"Arial\" -V monofont=\"Courier New\" -V geometry=portrait -V columns=onecolumn -V fontsize=11pt -V title=\"#{doc.xpath("//div/div/b")[0].text}\"")
      variables.close

      title_page = File.new("0000.md", "w")
      contents = <<-CONTENTS
\\thispagestyle{empty}
\\maketitle

      CONTENTS
      title_page.puts(contents)
      title_page.close

      #puts File.size? "temp.html"
      Open3.popen3('pandoc temp.html -o 0001.md') do |stdin, stdout|
        stdout.readlines
      end
      #IO.foreach("0000.md"){|block| puts block}

      chapters = doc.xpath('//form//select[@name="chapter"]/option').count
      if chapters > 1
        #append chapter 1
        chapter1 = File.new("0001.temp", "w")
        chapter1.puts "\#\# Chapter 1"
        chapter1.puts
        IO.foreach("0001.md") do |line|
          chapter1.puts line
        end
        chapter1.close
        FileUtils.rm("0001.md")
        File.rename("0001.temp", "0001.md")
        (2..chapters).each do |chapter| 
          tempfile = File.new("temp.html", "w")
          tempfile.puts "<h2>Chapter #{chapter}</h2>"
          pull = HTTParty.get("#{story_url}#{chapter}/")
          doc = Nokogiri::HTML(pull.body)
          doc.css(".storytext")[0].children.each do |paragraph|
            if /^<(p|hr|i|b)/.match paragraph.to_s
              tempfile.puts paragraph
            end
          end
          tempfile.close
          #puts File.size? "temp.html"
          Open3.popen3("pandoc temp.html -o #{"%04d" % chapter}.md") do |stdin, stdout|
            stdout.readlines
          end

        end
      end
      Dir.chdir "../" 
    end

    def build_story
      return unless check_story_dir
      combine_mds
      convert_to_pdf
    end

    def combine_mds
      combined = File.new("#{@story_id}/combined.md", "w")
      chapter_mds.each do |chapter|
        IO.foreach("#{chapter}") do |line|
          combined.puts(line)
        end
        combined.puts("\\clearpage")
      end
      combined.close
    end

    def convert_to_pdf
      Dir.chdir @story_id
      
      command = "markdown2pdf --xetex --template=xetex.template --toc #{IO.readlines("variables.txt")[0].strip} combined.md"
      Open3.popen3(command) do |stdin, stdout, stderr|
        stdout.readlines
        stderr.readlines
      end
      Dir.chdir "../" 
    end
  end
end
