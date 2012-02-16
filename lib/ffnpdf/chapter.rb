require 'httparty'
require 'nokogiri'
require 'fileutils'

module Ffnpdf
  class Chapter

    attr_accessor :story_url, :chapter, :doc

    def initialize(story_url, chapter)
      self.story_url = story_url
      self.chapter = chapter
    end

    def pull_and_convert
      pull_chapter
      convert_to_md
    end

    def pull_chapter
      puts "pulling chapter #{chapter}"
      pull = HTTParty.get(story_url)
      self.doc = Nokogiri::HTML(pull.body)
      content = doc.css(".storytext")[0].inner_html
      content = content.gsub(/<div class.*?\/div>/m, "")
      content = content.gsub(/<hr.*?>/, "<hr/><p>")
      puts "saving as #{padded_ch}.html"
      tempfile = File.new("#{padded_ch}.html", "w")
      tempfile.puts(content)
      tempfile.close
    end

    def convert_to_md
      puts "converting #{padded_ch}.html to #{padded_ch}.md"
      Converter.exec("pandoc #{padded_ch}.html -o #{padded_ch}.md")
      
      if chapter ==1 or chapter_title
        tempfile = File.new("#{padded_ch}.temp", "w")
        if chapter == 1
          tempfile.puts "\\pagenumbering{arabic}"
          tempfile.puts "\\setcounter{page}{1}"
          tempfile.puts
        end

        if (chapter_title)
          tempfile.puts "\#\# #{chapter_title}"
          tempfile.puts
        end
        IO.foreach("#{padded_ch}.md") do |line|
          tempfile.puts line
        end
        tempfile.close
        FileUtils.rm("#{padded_ch}.md")
        File.rename("#{padded_ch}.temp", "#{padded_ch}.md")
      end
    end

    def padded_ch
      "%04d" % chapter
    end

    def chapter_title
      if doc.xpath('//form//select[@name="chapter"]/option').count > 1
        doc.xpath('//form//select[@name="chapter"]/option')[chapter - 1].text.gsub(/^[\d]*?\. /, "")
      else
        nil
      end
    end

  end
end
