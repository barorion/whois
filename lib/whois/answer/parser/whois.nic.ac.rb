#
# = Ruby Whois
#
# An intelligent pure Ruby WHOIS client and parser.
#
#
# Category::    Net
# Package::     Whois
# Author::      Simone Carletti <weppos@weppos.net>
# License::     MIT License
#
#--
#
#++


require 'whois/answer/parser/base'


module Whois
  class Answer
    class Parser

      #
      # = whois.nic.ac parser
      #
      # Parser for the whois.nic.ac server.
      #
      class WhoisNicAc < Base

        property_not_supported :disclaimer


        property_supported :domain do
          @domain ||= if content_for_scanner =~ /Domain "(.+?)"/
            $1.downcase
          end
        end

        property_not_supported :domain_id


        property_not_supported :referral_whois

        property_not_supported :referral_url


        property_supported :status do
          @status ||= if available?
            :available
          else
            :registered
          end
        end

        property_supported :available? do
          @available  ||= !!(content_for_scanner =~ /- Available/)
        end

        property_supported :registered? do
          @registered ||= !available?
        end


        property_not_supported :created_on

        property_not_supported :updated_on

        property_not_supported :expires_on


        property_not_supported :registrar

        property_not_supported :registrant_contact

        property_not_supported :admin_contact

        property_not_supported :technical_contact


        property_not_supported :nameservers

      end

    end
  end
end
