require "spec_helper"

describe Whois::Server::Adapters::Afilias do

  before(:each) do
    @definition = [:tld, ".test", "whois.test", {}]
    @server = klass.new(*@definition)
  end


  describe "#query" do
    context "without referral" do
      it "returns the WHOIS record" do
        response = "No match for DOMAIN.TEST."
        expected = response
        @server.expects(:ask_the_socket).with("domain.test", "whois.afilias-grs.info", 43, nil, nil).returns(response)

        record = @server.query("domain.test")
        record.to_s.should  == expected
        record.parts.should have(1).part
        record.parts.should == [Whois::Answer::Part.new(response, "whois.afilias-grs.info")]
      end
    end

    context "with referral" do
      it "follows all referrals" do
        referral = File.read(fixture("referrals/afilias.bz.txt"))
        response = "Match for DOMAIN.TEST."
        expected = referral + "\n" + response
        @server.expects(:ask_the_socket).with("domain.test", "whois.afilias-grs.info", 43, nil, nil).returns(referral)
        @server.expects(:ask_the_socket).with("domain.test", "whois.belizenic.bz", 43, nil, nil).returns(response)

        record = @server.query("domain.test")
        record.to_s.should  == expected
        record.parts.should have(2).parts
        record.parts.should == [Whois::Answer::Part.new(referral, "whois.afilias-grs.info"), Whois::Answer::Part.new(response, "whois.belizenic.bz")]
      end
    end
  end

end
