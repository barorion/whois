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


module Whois
  class Server
    module Adapters

      #
      # = Verisign Adapter
      #
      # Provides ability to query Verisign WHOIS interfaces.
      #
      class Verisign < Base

        # Executes a WHOIS query to the Verisign WHOIS interface,
        # resolving any intermediate referral,
        # and appends the response to the client buffer.
        #
        # @param  [String] string
        # @return [void]
        #
        def request(string)
          response = query_the_socket("=#{string}", host, DEFAULT_WHOIS_PORT)
          append_to_buffer response, host

          if endpoint = extract_referral(response)
            response = query_the_socket(string, endpoint, DEFAULT_WHOIS_PORT)
            append_to_buffer response, endpoint
          end
        end


        private

          def extract_referral(response)
            if response =~ /Domain Name:/
              endpoint = response.scan(/Whois Server: (.+?)$/).flatten.last
              endpoint.strip!
              endpoint = nil  if endpoint == "not defined"
              endpoint
            end
          end

      end

    end
  end
end
