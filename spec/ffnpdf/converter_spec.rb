require 'spec_helper'

describe Ffnpdf::Converter do
  context "exec" do
    it "should be able to run commands" do
      Ffnpdf::Converter.exec("pwd")
    end
    it "should be able to run syncrhonously" do
      Ffnpdf::Converter.exec("rm temp.txt")
      Ffnpdf::Converter.exec("pwd > temp.txt")
      File.exists?("temp.txt").should == true
    end
  end
end
