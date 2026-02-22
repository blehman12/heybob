# Twilio Credentials Setup
# ========================
#
# EVM1 reads Twilio credentials in this order:
#   1. Rails encrypted credentials (preferred for production)
#   2. ENV variables (fallback — good for Railway)
#
# ── Option A: Rails encrypted credentials ──
#
# Run: bundle exec rails credentials:edit
# Add this block:
#
#   twilio:
#     account_sid: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#     auth_token:  your_auth_token_here
#     phone_number: +15035550100
#
# ── Option B: ENV variables (Railway / .env) ──
#
# Set these environment variables:
#   TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#   TWILIO_AUTH_TOKEN=your_auth_token_here
#   TWILIO_PHONE_NUMBER=+15035550100
#
# On Railway: Settings → Variables → add each one
#
# ── Getting your Twilio credentials ──
#
# 1. Sign up at https://console.twilio.com
# 2. Account SID and Auth Token are on the dashboard homepage
# 3. Phone number: buy one at https://console.twilio.com/us1/develop/phone-numbers/manage/buy
#    - US number costs ~$1.15/month
#    - SMS costs ~$0.0079/message outbound
#
# ── Testing locally ──
#
# Without real credentials, broadcasts save to DB but SMS silently skips
# (logs a warning). Safe to develop without Twilio configured.
#
# To test SMS delivery, add a verified test number in Twilio console
# (free trial requires verifying recipient numbers first).
#
# ── Cost estimate for Sakuracon ──
#
# 500 opt-ins × 5 broadcasts = 2,500 messages × $0.008 = ~$20
# Plus ~$1.15/month for the phone number
