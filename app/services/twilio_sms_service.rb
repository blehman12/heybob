# TwilioSmsService
# Single responsibility: send one SMS via Twilio REST API.
# Returns a result struct so callers can check success without rescuing.
#
# Usage:
#   result = TwilioSmsService.send(to: '+15035550100', body: 'Hello!')
#   result.success?   # => true / false
#   result.error      # => nil or error message string
#   result.sid        # => Twilio message SID on success

class TwilioSmsService
  Result = Struct.new(:success, :sid, :error, keyword_init: true) do
    def success? = success
  end

  # Normalize US phone numbers to E.164 (+1XXXXXXXXXX)
  # Pass-through if already E.164 or non-US
  def self.normalize_phone(phone)
    return phone if phone.blank?
    digits = phone.gsub(/\D/, '')
    return "+#{digits}" if digits.length == 11 && digits.start_with?('1')
    return "+1#{digits}" if digits.length == 10
    phone  # return as-is if we can't normalize
  end

  def self.send(to:, body:)
    account_sid = Rails.application.credentials.twilio&.fetch(:account_sid, nil) ||
                  ENV['TWILIO_ACCOUNT_SID']
    auth_token  = Rails.application.credentials.twilio&.fetch(:auth_token, nil) ||
                  ENV['TWILIO_AUTH_TOKEN']
    from_number = Rails.application.credentials.twilio&.fetch(:phone_number, nil) ||
                  ENV['TWILIO_PHONE_NUMBER']

    if account_sid.blank? || auth_token.blank? || from_number.blank?
      Rails.logger.warn "[TwilioSmsService] Missing credentials — SMS not sent to #{to}"
      return Result.new(success: false, error: 'Twilio credentials not configured')
    end

    normalized_to = normalize_phone(to)

    if normalized_to.blank?
      return Result.new(success: false, error: "Invalid phone number: #{to}")
    end

    client = Twilio::REST::Client.new(account_sid, auth_token)

    message = client.messages.create(
      from: from_number,
      to:   normalized_to,
      body: body
    )

    Result.new(success: true, sid: message.sid, error: nil)

  rescue Twilio::REST::RestError => e
    Rails.logger.error "[TwilioSmsService] Twilio error for #{to}: #{e.message}"
    Result.new(success: false, sid: nil, error: e.message)
  rescue => e
    Rails.logger.error "[TwilioSmsService] Unexpected error for #{to}: #{e.message}"
    Result.new(success: false, sid: nil, error: e.message)
  end
end
