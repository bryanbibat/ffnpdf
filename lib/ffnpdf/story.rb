require 'httparty'
require 'nokogiri'

module Ffnpdf
  class Story
    FFN_URL = "http://www.fanfiction.net/"

    attr_accessor :custom_url, :error

    def initialize(story_id)
      @story_id = story_id
    end

    def check_story
      unless /^[\d]*$/.match @story_id
        @error = "Story ID is invalid"
        return false
      end

      test_pull = HTTParty.get(story_url)
      unless test_pull.code == 200
        @error = "Story does not exist (#{story_url})"
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
      doc.css(".storytext p").each do |paragraph|
        tempfile.puts paragraph
      end
      tempfile.close
      #puts File.size? "temp.html"
      `pandoc temp.html -o 0000.md`
      #IO.foreach("0000.md"){|block| puts block}
      Dir.chdir "../" 
    end
  end
end
