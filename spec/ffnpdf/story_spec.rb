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

end
