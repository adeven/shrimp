#encoding: UTF-8
require 'spec_helper'

def valid_pdf(io)
  case io
    when File
      io.read[0...4] == "%PDF"
    when String
      io[0...4] == "%PDF" || File.open(io).read[0...4] == "%PDF"
  end
end

def testfile
  File.expand_path('../test_file.html', __FILE__)
end


describe Shrimp do
  before(:all) do 
    Shrimp.configure do |config|
      config.phantomjs = '/home/justin/Downloads/phantomjs-1.9.1-linux-x86_64/bin/phantomjs'
    end
    @executable = Shrimp.configuration.options[:phantomjs]
  end

  describe Shrimp::Phantom do
    before do
      Shrimp.configure do |config|
        config.format = 'Letter'
        config.margin = '1cm'
        config.tmpdir = Dir.tmpdir
        config.fail_silently = false
      end
    end

    it "should initialize attributes" do
      phantom = Shrimp::Phantom.new(@executable, "file://#{testfile}", 
                                    { :margin => "2cm" }, { }, 
                                    "#{Dir.tmpdir}/test.pdf")
      phantom.source.to_s.should eq "file://#{testfile}"
      phantom.options[:margin].should eq "2cm"
      phantom.outfile.should eq "#{Dir.tmpdir}/test.pdf"
    end

    it "should accept a local file url" do
      phantom = Shrimp::Phantom.new(@executable,"file://#{testfile}")
      phantom.source.should be_url
    end

    it "should accept a URL as source" do
      phantom = Shrimp::Phantom.new(@executable,"http://google.com")
      phantom.source.should be_url
    end

    it "should parse options into a cmd line" do
      phantom = Shrimp::Phantom.new(@executable, "file://#{testfile}", 
                                    { format: 'Letter', margin: "2cm" }, 
                                    { }, "#{Dir.tmpdir}/test.pdf")
      phantom.cmd.should include "test.pdf Letter 1 2cm portrait"
      phantom.cmd.should include "file://#{testfile}"
      phantom.cmd.should include "lib/shrimp/rasterize.js"
    end

    context "rendering to a file" do
      before(:all) do
        phantom = Shrimp::Phantom.new(@executable, "file://#{testfile}", 
                                      { :margin => "2cm" }, { }, 
                                      "#{Dir.tmpdir}/test.pdf")
        @result = phantom.to_file
      end

      it "should return a File" do
        @result.should be_a File
      end

      it "should be a valid pdf" do
        valid_pdf(@result)
      end
    end

    context "rendering to a pdf" do
      before(:all) do
        @phantom = Shrimp::Phantom.new(@executable, "file://#{testfile}", 
                                       { :margin => "2cm" }, { })
        @result  = @phantom.to_pdf("#{Dir.tmpdir}/test.pdf")
      end

      it "should return a path to pdf" do
        @result.should be_a String
        @result.should eq "#{Dir.tmpdir}/test.pdf"
      end

      it "should be a valid pdf" do
        valid_pdf(@result)
      end
    end

    context "rendering to a String" do
      before(:all) do
        phantom = Shrimp::Phantom.new(@executable, "file://#{testfile}", 
                                      { :margin => "2cm" }, { })
        @result = phantom.to_string("#{Dir.tmpdir}/test.pdf")
      end

      it "should return the File IO String" do
        @result.should be_a String
      end

      it "should be a valid pdf" do
        valid_pdf(@result)
      end
    end

    context "failing loudly" do
      it "should raise a RenderingError" do
        phantom = Shrimp::Phantom.new(@executable, "file://foo/bar")
        expect { phantom.run }.to raise_error(Shrimp::RenderingError)
      end
    end

    context "failing silently" do
      it "should return nil" do
        Shrimp.configure do |config|
          config.fail_silently = true
        end
        phantom = Shrimp::Phantom.new(@executable, "file:///foo/bar")
        phantom.run.should eq(nil)
      end
    end
  end
end
