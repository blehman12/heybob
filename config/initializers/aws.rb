# frozen_string_literal: true

# aws-sdk-s3 >= 1.119 changed default checksum behavior to "when_supported",
# which adds checksum headers to GET operations and can cause SignatureDoesNotMatch
# errors from S3 when analyzing blobs after upload. Revert to "when_required"
# which only adds checksums when AWS mandates them (e.g., multipart uploads).
if defined?(Aws)
  Aws.config.update(
    request_checksum_calculation: "when_required",
    response_checksum_validation: "when_required"
  )
end
