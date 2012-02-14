module Ffnpdf
  class Converter
    def self.exec(command)
      `#{command}`
    end

    def self.convert_to_pdf(story_id)
      Dir.chdir story_id
      
      command = "markdown2pdf --xetex --template=xetex.template --toc #{IO.readlines("variables.txt")[0].strip} combined.md"
      Converter.exec(command)

      Dir.chdir "../" 
    end
  end
end
