require 'spec_helper'

describe Ffnpdf::Story do

  it "should create a story" do
    story = Ffnpdf::Story.new("1234567")
    story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
    story.check_story.should == true
  end

  it "should allow setting custom url" do
    story = Ffnpdf::Story.new("1234567")
    story.story_url.should == "http://www.fanfiction.net/s/1234567/"
    story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
    story.story_url.should == "http://bryanbibat.github.com/ffnpdf-test/s/1234567/"
  end

  it "should check if story id is valid" do
    blah = Ffnpdf::Story.new("blah")
    blah.check_story.should == false
    blah.error.should == "Story ID is invalid"
  end

  it "should check story's existence" do
    story = Ffnpdf::Story.new("0")
    story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
    story.check_story.should == false
    story.error.should == "Story does not exist (#{story.story_url})"
  end

  context "pulling" do
    before :each do
      @story = Ffnpdf::Story.new("1234567")
      @story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
    end

    after :each do
      if File.directory?("1234567") 
        FileUtils.rm_rf("1234567")
      end
    end

    it "should create a story directory" do
      pwd = Dir.pwd
      @story.pull_story
      Dir.pwd.should == pwd
      File.should be_directory("1234567")
      File.should exist("1234567/0001.md")
      File.should exist("1234567/0000.md")
      File.should exist("1234567/variables.txt")
      File.should exist("1234567/xetex.template")
    end
  end

  context "building" do
    after :each do
      if File.directory?("1234567") 
        FileUtils.rm_rf("1234567")
      end
    end

    it "should check non existence of directory" do
      story = Ffnpdf::Story.new("1234567")
      story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
      story.check_story_dir.should == false
      story.error.should == "Story folder does not exist (1234567/)"
    end

    it "should check non existence of files" do
      story = Ffnpdf::Story.new("1234567")
      story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
      story.pull_story
      story = Ffnpdf::Story.new("1234567")
      story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
      FileUtils.rm("1234567/0001.md")
      FileUtils.rm("1234567/0000.md")
      story.check_story_dir.should == false
      story.error.should == "Story folder does not have markdown files (1234567/)"
    end

    it "should check existence of directory" do
      story = Ffnpdf::Story.new("1234567")
      story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
      story.pull_story
      story = Ffnpdf::Story.new("1234567")
      story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
      story.check_story_dir.should == true
    end

  end

  context "pulling multi" do
    before :each do
      @story = Ffnpdf::Story.new("0000001")
      @story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
    end

    after :each do
      if File.directory?("0000001") 
        FileUtils.rm_rf("0000001")
      end
    end

    it "should create a story directory" do
      pwd = Dir.pwd
      @story.pull_story
      Dir.pwd.should == pwd
      File.should be_directory("0000001")
      File.should exist("0000001/0001.md")
      File.should exist("0000001/0002.md")
      File.should exist("0000001/0003.md")
    end
  end

  context "building multi" do
    before :each do
      @story = Ffnpdf::Story.new("0000001")
      @story.custom_url = "http://bryanbibat.github.com/ffnpdf-test/"
    end

    after :each do
      if File.directory?("0000001") 
        #FileUtils.rm_rf("0000001")
      end
    end

    it "should build a story" do
      pwd = Dir.pwd
      @story.pull_story
      Dir.pwd.should == pwd
      @story.build_story
      Dir.pwd.should == pwd
      File.should exist("0000001/combined.md")
      File.should exist("0000001/combined.pdf")
    end

  end
end
