module Ffnpdf
  class Exec
    def initialize(argv)
      invalid = false
      if argv.size == 0
        invalid = true
      elsif /^[\d]+$/.match argv[0]
        
      elsif argv[0] == "pull" and /^[\d]+$/.match argv[1]
        story = Ffnpdf::Story.new(argv[1])
        if story.check_story
          story.pull_story
        else
          $stderr.puts story.error
        end
      elsif argv[0] == "build"
        story = Ffnpdf::Story.new(argv[1])
        if story.check_story_directory
          story.build_story
        else
          $stderr.puts story.error
        end
      else
        invalid = true
      end

      if invalid
        $stderr.puts <<-MSG
possible commands: 
  ffnpdf [story_id] 
    - scrapes and generates pdf of story at [story_id]/ folder
  ffnpdf pull [story_id] 
    - scrapes story and puts the markdown files at [story_id]/ folder
  ffnpdf build [story_id]
    - compiles *.md files at [story_id]/ into a single pdf
        MSG
      end
    end
  end
end
