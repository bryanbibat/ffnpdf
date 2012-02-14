module Ffnpdf
  class Exec
    def initialize(argv)
      invalid = false
      if argv.size == 0
        invalid = true
      elsif /^[\d]+$/.match argv[0]
        story = Ffnpdf::Story.new(argv[1])
        if story.check_story
          story.pull_story
          story.build_story
        else
          $stderr.puts story.error
        end
      elsif argv[0] == "pull" and /^[\d]+$/.match argv[1]
        story = Ffnpdf::Story.new(argv[1])
        if story.check_story
          story.pull_story
        else
          $stderr.puts story.error
        end
      elsif argv[0] == "build" and /^[\d]+$/.match argv[1]
        story = Ffnpdf::Story.new(argv[1])
        if story.check_story_dir
          story.build_story
        else
          $stderr.puts story.error
        end
      elsif argv[0] == "convert" and /^[\d]+$/.match argv[1]
        story = Ffnpdf::Story.new(argv[1])
        if story.check_story_dir
          story.convert_to_pdf
        else
          $stderr.puts story.error
        end
      else
        invalid = true
      end

      if invalid
        $stderr.puts <<-MSG
Usage
  ffnpdf [STORY_ID]
  ffnpdf [COMMAND] [STORY_ID]

Description
  Scrapes story from FanFiction.net and generates pdf at STORY_ID/ folder.

  The following commands are available
    pull        scrapes story and puts the markdown and template files at STORY_ID/ folder
    build       compiles *.md files at STORY_ID/ into a single pdf
    convert     converts STORY_ID/combined.md  to pdf using the template files
MSG
      end
    end
  end
end
