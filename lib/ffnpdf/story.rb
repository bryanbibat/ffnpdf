require 'httparty'
require 'nokogiri'
require 'fileutils'
require 'open3'

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

      unless Nokogiri::HTML(test_pull.body).css(".storytext")
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
      Dir["#{@story_id}/*"].grep(/.md$/).reject { |x| /combined.md$/.match x }.sort
    end

    def story_url
      custom_url ? "#{@custom_url}s/#{@story_id}/" : "#{FFN_URL}s/#{@story_id}/"
    end

    def pull_story
      return unless check_story
      FileUtils.mkdir_p @story_id
      Dir.chdir @story_id
      
      tempfile = File.new("temp.html", "w")
      puts "pulling first chapter"
      pull = HTTParty.get(story_url)
      doc = Nokogiri::HTML(pull.body)
      doc.css(".storytext")[0].children.each do |paragraph|
        if /^<(p|hr|i|b)/.match paragraph.to_s
          tempfile.puts paragraph
        end
      end
      tempfile.close

      Converter.exec 'pandoc temp.html -o 0001.md'

      title = doc.xpath("//div/div/b")[0].text
      author = doc.xpath("//div/table//a[not(@title or @onclick)]")[0].text

      generate_template(title, author, get_doc_date(doc))
      generate_variables_file
      generate_title_page

      chapters = doc.xpath('//form//select[@name="chapter"]/option').count
      if chapters > 1
        append_header_to_ch1

        (2..chapters).each do |chapter| 
          puts "pulling chapter #{chapter}"
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
          Converter.exec("pandoc temp.html -o #{"%04d" % chapter}.md")
        end
      end
      Dir.chdir "../" 
    end

    def get_doc_date(doc)
      parsing = doc.xpath('//div[@style="padding-left:1em;padding-right:1em;padding-top:0.5em;"]')[0].text
      match = /Updated: (.{8})/.match parsing
      if match
        return Date.strptime(match[1], "%m-%d-%y").strftime("%d %B %Y")
      else
        match = /Published: (.{8})/.match parsing
        return Date.strptime(match[1], "%m-%d-%y").strftime("%d %B %Y")
      end
    end

    def generate_template(title, author, date)
      template = File.new("xetex.template", "w")
      contents = <<-CONTENTS
% Shamelessly ripped off from https://github.com/karlseguin/the-little-mongodb-book
\\documentclass[$fontsize$,$columns$]{book}
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

$if(fancy-enums)$
\\usepackage{enumerate}
$endif$
\\setcounter{secnumdepth}{-1}

\\usepackage{hyperref}
\\hypersetup{
    colorlinks=true,%
    citecolor=Black,%
    filecolor=Black,%
    linkcolor=Black,%
    urlcolor=Black
}

\\title{#{title}}
\\author{#{author}}
\\date{#{date}}
\\begin{document}
$body$
\\end{document}
      CONTENTS
      template.puts(contents)
      template.close
    end

    def generate_variables_file
      variables = File.new("variables.txt", "w")
      variables.puts("-V paper=a4paper -V hmargin=3cm -V vmargin=3cm -V mainfont=\"DejaVu Serif\" -V sansfont=\"DejaVu Sans\" -V monofont=\"DejaVu Sans Mono\" -V geometry=portrait -V columns=onecolumn -V fontsize=11pt ")
      variables.close
    end

    def generate_title_page
      title_page = File.new("0000.md", "w")
      contents = <<-CONTENTS
\\maketitle
\\pagenumbering{roman}
\\tableofcontents

      CONTENTS
      title_page.puts(contents)
      title_page.close
    end

    def append_header_to_ch1
      chapter1 = File.new("0001.temp", "w")
      chapter1.puts "\\pagenumbering{arabic}"
      chapter1.puts "\\setcounter{page}{1}"
      chapter1.puts
      chapter1.puts "\#\# Chapter 1"
      chapter1.puts
      IO.foreach("0001.md") do |line|
        chapter1.puts line
      end
      chapter1.close
      FileUtils.rm("0001.md")
      File.rename("0001.temp", "0001.md")
    end

    def build_story
      return unless check_story_dir
      combine_mds
      convert_to_pdf
    end

    def combine_mds
      puts "combining chapters"
      combined = File.new("#{@story_id}/combined.md", "w")
      chapter_mds.each do |chapter|
        IO.foreach("#{chapter}") do |line|
          combined.puts(line)
        end
        combined.puts("\\clearpage")
        combined.puts()
      end
      combined.close
    end

    def convert_to_pdf
      Converter.convert_to_pdf(@story_id)
    end
  end
end
