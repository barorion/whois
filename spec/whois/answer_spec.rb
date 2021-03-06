require "spec_helper"

describe Whois::Answer do

  before(:each) do
    @server   = Whois::Server.factory(:tld, ".foo", "whois.example.test")
    @parts    = [
        Whois::Answer::Part.new("This is a answer from foo.", "foo.example.test"),
        Whois::Answer::Part.new("This is a answer from bar.", "bar.example.test")
    ]
    @content  = @parts.map(&:body).join("\n")
  end


  describe "#initialize" do
    it "requires a server and parts" do
      lambda { klass.new }.should raise_error(ArgumentError)
      lambda { klass.new(@server) }.should raise_error(ArgumentError)
      lambda { klass.new(@server, @parts) }.should_not raise_error
    end
    
    it "sets server and parts from arguments" do
      instance = klass.new(@server, @parts)
      instance.server.should be(@server)
      instance.parts.should be(@parts)

      instance = klass.new(nil, nil)
      instance.server.should be_nil
      instance.parts.should be_nil
    end
  end


  describe "#to_s" do
    it "delegates to #content" do
      klass.new(nil, [@parts[0]]).to_s.should == @parts[0].body
      klass.new(nil, @parts).to_s.should == @parts.map(&:body).join("\n")
      klass.new(nil, []).to_s.should == ""
    end
  end

  describe "#inspect" do
    it "inspects the answer content" do
      klass.new(nil, [@parts[0]]).inspect.should == @parts[0].body.inspect
    end

    it "joins multiple parts" do
      klass.new(nil, @parts).inspect.should == @parts.map(&:body).join("\n").inspect
    end

    it "returns an empty string when no parts" do
      klass.new(nil, []).inspect.should == "".inspect
    end
  end

  describe "#==" do
    it "returns true when other is the same instance" do
      one = two = klass.new(@server, @parts)

      (one == two).should be_true
      (one.eql? two).should be_true
    end

    it "returns true when other has same class and has the same parts" do
      one, two = klass.new(@server, @parts), klass.new(@server, @parts)

      (one == two).should be_true
      (one.eql? two).should be_true
    end

    it "returns true when other has descendant class and has the same parts" do
      subklass = Class.new(klass)
      one, two = klass.new(@server, @parts), subklass.new(@server, @parts)

      (one == two).should be_true
      (one.eql? two).should be_true
    end

    it "returns true when other has same class and has equal parts" do
      one, two = klass.new(@server, @parts), klass.new(@server, @parts.dup)
      (one == two).should be_true
      (one.eql? two).should be_true
    end

    it "returns true when other has same class, different server and the same parts" do
      one, two = klass.new(@server, @parts), klass.new(nil, @parts)
      (one == two).should be_true
      (one.eql? two).should be_true
    end

    it "returns false when other has different class and has the same parts" do
      one, two = klass.new(@server, @parts), Struct.new(:server, :parts).new(@server, @parts)

      (one == two).should be_false
      (one.eql? two).should be_false
    end

    it "returns false when other has different parts" do
      one, two = klass.new(@server, @parts), klass.new(@server, [])

      (one == two).should be_false
      (one.eql? two).should be_false
    end

    it "returns true when other is string and has the same content", :deprecated => true do
      one, two = klass.new(@server, @parts), klass.new(@server, @parts).to_s

      (one == two).should be_true
      (one.eql? two).should be_true
    end

    it "returns false when other is string and has different content", :deprecated => true do
      one, two = klass.new(@server, @parts), "different"

      (one == two).should be_false
      (one.eql? two).should be_false
    end
  end


  describe "match" do
    it "delegates to content" do
      klass.new(@server, @parts).match(/answer/).should be_a(MatchData)
      klass.new(@server, @parts).match(/answer/)[0].should == "answer"

      klass.new(@server, @parts).match(/nomatch/).should be_nil
    end
  end

  describe "match" do
    it "calls match and checks for match" do
      klass.new(@server, @parts).match?(/answer/).should  == true
      klass.new(@server, @parts).match?(/nomatch/).should == false
    end
  end


  describe "#content" do
    it "returns the part body" do
      klass.new(nil, [@parts[0]]).content.should == @parts[0].body
    end

    it "joins multiple parts" do
      klass.new(nil, @parts).content.should == @parts.map(&:body).join("\n")
    end

    it "returns an empty string when no parts" do
      klass.new(nil, []).content.should == ""
    end
  end

  describe "#parser" do
    it "returns a Parser" do
      klass.new(nil, @parts).parser.should be_a(Whois::Answer::Parser)
    end

    it "initializes the parser with self" do
      answer = klass.new(nil, @parts)
      answer.parser.answer.should be(answer)
    end

    it "memoizes the value" do
      answer = klass.new(nil, @parts)
      answer.instance_eval { @parser }.should be_nil
      parser = answer.parser
      answer.instance_eval { @parser }.should be(parser)
    end
  end


  describe "#properties" do
    it "returns a Hash" do
      klass.new(nil, []).properties.should be_a(Hash)
    end

    it "returns both nil and not-nil values" do
      r = klass.new(nil, [])
      r.expects(:domain).returns("")
      r.expects(:created_on).returns(nil)
      r.expects(:expires_on).returns(Time.parse("2010-10-10"))
      p = r.properties
      p[:domain].should == ""
      p[:created_on].should == nil
      p[:expires_on].should == Time.parse("2010-10-10")
    end

    it "fetches all parser property" do
      klass.new(nil, []).properties.keys.should =~ Whois::Answer::Parser::PROPERTIES 
    end
  end


  class Whois::Answer::Parser::WhoisPropertiesTest < Whois::Answer::Parser::Base
    property_supported :status do
      nil
    end
    property_supported :created_on do
      Date.parse("2010-10-20")
    end
    property_not_supported :updated_on
    # property_not_defined :expires_on
  end

  describe "#property_supported?" do
    it "returns true if the property is supported" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.property_supported?(:status).should == true
      r.property_supported?(:created_on).should == true
    end

    it "returns false if the property is not supported" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.property_supported?(:updated_on).should == false
    end

    it "returns false if the property is not defined" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.property_supported?(:expires_on).should == false
    end
  end

  describe "property" do
    it "returns value when the property is supported" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.created_on.should == Date.parse("2010-10-20")
    end

    it "returns nil when the property is not supported" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.updated_on.should be_nil
    end

    it "returns nil when the property is not implemented" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.expires_on.should be_nil
    end
  end

  describe "property?" do
    it "returns true when the property is supported and has no value" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.status?.should == false
    end

    it "returns false when the property is supported and has q value" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.created_on?.should == true
    end

    it "returns false when the property is not supported" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.updated_on?.should == false
    end

    it "returns false when the property is not implemented" do
      r = klass.new(nil, [Whois::Answer::Part.new("", "whois.properties.test")])
      r.expires_on?.should == false
    end
  end


  describe "#changed?" do
    it "raises if the argument is not an instance of the same class" do
      lambda do
        klass.new(nil, []).changed?(Object.new)
      end.should raise_error

      lambda do
        klass.new(nil, []).changed?(klass.new(nil, []))
      end.should_not raise_error
    end
  end

  describe "#unchanged?" do
    it "raises if the argument is not an instance of the same class" do
      lambda do
        klass.new(nil, []).unchanged?(Object.new)
      end.should raise_error

      lambda do
        klass.new(nil, []).unchanged?(klass.new(nil, []))
      end.should_not raise_error
    end

    it "returns true if self and other references the same object" do
      instance = klass.new(nil, [])
      instance.unchanged?(instance).should be_true
    end

    it "delegates to #parser if self and other references different objects" do
      other = klass.new(nil, @parts)
      instance = klass.new(nil, @parts)
      instance.parser.expects(:unchanged?).with(other.parser)

      instance.unchanged?(other)
    end
  end

  describe "#contacts" do
    it "delegates to parser" do
      answer = klass.new(nil, [])
      answer.parser.expects(:contacts).returns([:one, :two])
      answer.contacts.should == [:one, :two]
    end
  end

  describe "#throttle?" do
    it "delegates to #parser" do
      instance = klass.new(nil, @parts)
      instance.parser.expects(:throttle?)

      instance.throttle?
    end
  end


  describe "method_missing" do
    context "when a parser property"
    context "when a parser method"

    context "when a parser question method/property" do
      it "calls the corresponding no-question method" do
        answer = klass.new(nil, [])
        answer.expects(:status)
        answer.status?
      end

      it "returns true if the property is not nil" do
        answer = klass.new(nil, [])
        answer.expects(:status).returns("available")
        answer.status?.should == true
      end

      it "returns false if the property is nil" do
        answer = klass.new(nil, [])
        answer.expects(:status).returns(nil)
        answer.status?.should == false
      end
    end

    context "when a simple method" do
      it "passes the request to super" do
        Object.class_eval do
          def happy; "yes"; end
        end

        answer = klass.new(nil, [])
        lambda do
          answer.happy.should == "yes"
        end.should_not raise_error
        lambda do
          answer.sad
        end.should raise_error(NoMethodError)
      end

      it "doesn't catch all methods" do
        lambda do
          klass.new(nil, []).i_am_not_defined
        end.should raise_error(NoMethodError)
      end

      it "doesn't catch all question methods" do
        lambda do
          klass.new(nil, []).i_am_not_defined?
        end.should raise_error(NoMethodError)
      end
    end
  end

end
