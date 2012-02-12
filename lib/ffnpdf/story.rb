require 'httparty'

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


  end
end
