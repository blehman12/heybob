# BroadcastSmsJob
# Sends SMS to all pending receipts for a given broadcast.
# Each receipt is processed individually so one bad number
# doesn't block the rest. Sidekiq retries on failure.
#
# Enqueue: BroadcastSmsJob.perform_later(broadcast_id)

class BroadcastSmsJob < ApplicationJob
  queue_as :broadcasts

  # Retry up to 3 times with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(broadcast_id)
    broadcast = Broadcast.includes(broadcast_receipts: :con_opt_in).find(broadcast_id)

    Rails.logger.info "[BroadcastSmsJob] Starting broadcast ##{broadcast_id}: " \
                      "#{broadcast.recipient_count} recipients"

    sent_count    = 0
    failed_count  = 0

    broadcast.broadcast_receipts.pending.each do |receipt|
      opt_in = receipt.con_opt_in

      # Skip if no phone number
      unless opt_in.phone.present?
        receipt.update!(status: :failed)
        failed_count += 1
        next
      end

      result = TwilioSmsService.send(
        to:   opt_in.phone,
        body: broadcast.message
      )

      if result.success?
        receipt.update!(status: :delivered, delivered_at: Time.current)
        sent_count += 1
      else
        receipt.update!(status: :failed)
        Rails.logger.warn "[BroadcastSmsJob] Failed for receipt ##{receipt.id}: #{result.error}"
        failed_count += 1
      end

      # Small delay to respect Twilio rate limits (~1 msg/sec for free tier)
      # Remove or reduce in production with a paid number
      sleep 0.05
    end

    Rails.logger.info "[BroadcastSmsJob] Broadcast ##{broadcast_id} complete: " \
                      "#{sent_count} sent, #{failed_count} failed"
  end
end
