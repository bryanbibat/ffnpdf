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
      
      chapter1 = Chapter.new(story_url, 1)
      chapter1.pull_and_convert

      doc = chapter1.doc

      title = doc.xpath("//div/table//b")[0].text
      author = doc.xpath("//div/table//a[not(@title or @onclick)]")[0].text

      generate_template(title, author, get_doc_date(doc))
      generate_variables_file
      generate_title_page(chapter1.chapter_title)

      chapters = doc.xpath('//form//select[@name="chapter"]/option').count

      if chapters > 1
        (2..chapters).each do |chapter| 
          Chapter.new("#{story_url}#{chapter}/", chapter).pull_and_convert
        end
      end
      Dir.chdir "../" 
    end

    def get_doc_date(doc)
      parsing = doc.xpath('//div[@style="color:gray;"]')[0].text
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
\\usepackage{fontspec,xltxtra,xunicode}
\\defaultfontfeatures{Mapping=tex-text,Scale=MatchLowercase}
\\setmainfont{$mainfont$}
\\setsansfont{$sansfont$}
\\setmonofont{$monofont$}

\\setlength{\\parindent}{0pt}
\\setlength{\\parskip}{12pt plus 2pt minus 1pt}
\\linespread{1.2}

\\usepackage{listings}
\\usepackage[dvipsnames,usenames]{xcolor}

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

    def generate_title_page(has_toc = true)
      title_page = File.new("0000.md", "w")
      title = "\\maketitle\n"
      if has_toc
        title += <<-CONTENTS
\\pagenumbering{roman}
\\tableofcontents

        CONTENTS
      end
      title_page.puts(title)
      title_page.close
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
