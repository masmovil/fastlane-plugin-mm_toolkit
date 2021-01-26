module Fastlane
    module Actions
        module SharedValues
            WEBEX_MESSAGE_HOOKURL = :WEBEX_MESSAGE_HOOKURL
        end

        class WebexMessageAction < Action
            def self.run(params)
                uri = URI(params[:url])
                markdown = generate_webex_markdown(params)

                begin
                    res = Net::HTTP.post(uri, { "markdown" => markdown }.to_json, "Content-Type" => "application/json")
                rescue => exception
                    UI.error("Exception: #{exception}")
                ensure
                    if res.is_a?(Net::HTTPSuccess)
                        UI.success('Successfully sent Webex notification')
                    else
                        UI.verbose(res) unless res.nil?
                        message = "Error pushing Webex message. This is usually caused by a misspelled or an expired WEBEX_MESSAGE_URL"
                        if params[:fail_on_error]
                            UI.user_error!(message)
                        else
                            UI.error(message)
                        end
                    end
                end
            end

            #####################################################
            # @!group support functions
            #####################################################           

            def self.generate_webex_markdown(params)
                markdown = ""

                if params[:success] 
                    prefix = "✅"
                else
                    prefix = "🛑"
                end

                if params[:message_apply_format] 
                    markdown += "## #{prefix} #{params[:message]}"
                else 
                    markdown += "#{params[:message]}"
                end

                markdown += "\n\n" unless params[:payload].empty?

                markdown += params[:payload].map { |k, v|
                    ">**#{k.to_s}**  \n>#{v.to_s.gsub("\n", "  \n>")}  \n"
                }.join("")

                markdown
            end

            #####################################################
            # @!group Documentation
            #####################################################

            def self.description
                "Send message through webhook"
            end

            def self.details
                "Send message through webhook"
            end

            def self.available_options
                [
                    FastlaneCore::ConfigItem.new(key: :url,
                                                 env_name: "WEBEX_MESSAGE_URL",
                                                 sensitive: true,
                                                 description: "Create an Incoming WebHook for your Webex space",
                                                 optional: false,
                                                 verify_block: proc do |value|
                                                    UI.user_error!("Invalid URL, must start with https://") unless value.start_with?("https://")
                                                 end),                    
                    FastlaneCore::ConfigItem.new(key: :message,
                                                 env_name: "WEBEX_MESSAGE_MESSAGE",
                                                 description: "The message that should be displayed on Space. This supports the standard markup language"),
                    FastlaneCore::ConfigItem.new(key: :message_apply_format,
                                                 env_name: "WEBEX_MESSAGE_APPLY_FORMAT",
                                                 description: "Apply format to the given message? (true/false)",
                                                 optional: true,
                                                 default_value: true,
                                                 is_string: false),
                    FastlaneCore::ConfigItem.new(key: :payload,
                                                 env_name: "WEBEX_MESSAGE_PAYLOAD",
                                                 description: "Add additional information to this post. payload must be a hash containing any key with any value",
                                                 default_value: {},
                                                 is_string: false),
                    FastlaneCore::ConfigItem.new(key: :success,
                                                 env_name: "WEBEX_MESSAGE_SUCCESS",
                                                 description: "Was this build successful? (true/false)",
                                                 optional: true,
                                                 default_value: true,
                                                 is_string: false),
                    FastlaneCore::ConfigItem.new(key: :fail_on_error,
                                                 env_name: "WEBEX_MESSAGE_FAIL_ON_ERROR",
                                                 description: "Should an error sending the webex notification cause a failure? (true/false)",
                                                 optional: true,
                                                 default_value: false,
                                                 is_string: false)
                ]         
            end

            def self.authors
                ["sebastianvarela"]
            end

            def self.is_supported?(platform)
                [:ios, :mac].include? platform
            end
        end
    end
end
