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


      true
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
      #puts File.size? "temp.html"
      Open3.popen3('pandoc temp.html -o 0001.md') do |stdin, stdout|
        stdout.readlines
      end
      #IO.foreach("0000.md"){|block| puts block}

      chapters = doc.xpath('//form//select[@name="chapter"]/option').count
      if chapters > 1
        (2..chapters).each do |chapter| 
          tempfile = File.new("temp.html", "w")
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
  end
end
