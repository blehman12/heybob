# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_22_000002) do
  create_table "broadcast_receipts", force: :cascade do |t|
    t.integer "broadcast_id", null: false
    t.integer "con_opt_in_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["broadcast_id", "con_opt_in_id"], name: "index_broadcast_receipts_on_broadcast_id_and_con_opt_in_id", unique: true
    t.index ["broadcast_id"], name: "index_broadcast_receipts_on_broadcast_id"
    t.index ["con_opt_in_id"], name: "index_broadcast_receipts_on_con_opt_in_id"
    t.index ["status"], name: "index_broadcast_receipts_on_status"
  end

  create_table "broadcasts", force: :cascade do |t|
    t.integer "vendor_event_id", null: false
    t.text "message", null: false
    t.integer "channel", default: 0, null: false
    t.integer "scope", default: 0, null: false
    t.datetime "sent_at"
    t.integer "recipient_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sent_at"], name: "index_broadcasts_on_sent_at"
    t.index ["vendor_event_id", "sent_at"], name: "index_broadcasts_on_vendor_event_id_and_sent_at"
    t.index ["vendor_event_id"], name: "index_broadcasts_on_vendor_event_id"
  end

  create_table "con_opt_ins", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "vendor_event_id", null: false
    t.integer "user_id"
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.datetime "opted_in_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "email"], name: "index_con_opt_ins_on_event_id_and_email", unique: true, where: "email IS NOT NULL"
    t.index ["event_id", "phone"], name: "index_con_opt_ins_on_event_id_and_phone", unique: true, where: "phone IS NOT NULL"
    t.index ["event_id"], name: "index_con_opt_ins_on_event_id"
    t.index ["opted_in_at"], name: "index_con_opt_ins_on_opted_in_at"
    t.index ["user_id"], name: "index_con_opt_ins_on_user_id"
    t.index ["vendor_event_id"], name: "index_con_opt_ins_on_vendor_event_id"
  end

  create_table "event_participants", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_id", null: false
    t.integer "role", default: 0
    t.integer "rsvp_status", default: 0, null: false
    t.text "notes"
    t.datetime "invited_at"
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "rsvp_answers"
    t.datetime "checked_in_at"
    t.string "check_in_method"
    t.string "qr_code_token"
    t.integer "checked_in_by_id"
    t.string "guest_name"
    t.string "guest_email"
    t.string "guest_phone"
    t.boolean "is_guest", default: false
    t.index ["checked_in_at"], name: "index_event_participants_on_checked_in_at"
    t.index ["checked_in_by_id"], name: "index_event_participants_on_checked_in_by_id"
    t.index ["event_id"], name: "index_event_participants_on_event_id"
    t.index ["guest_email"], name: "index_event_participants_on_guest_email"
    t.index ["qr_code_token"], name: "index_event_participants_on_qr_code_token", unique: true
    t.index ["role"], name: "index_event_participants_on_role"
    t.index ["rsvp_status"], name: "index_event_participants_on_rsvp_status"
    t.index ["user_id", "event_id"], name: "index_event_participants_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_event_participants_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "event_date"
    t.time "start_time"
    t.time "end_time"
    t.integer "max_attendees"
    t.datetime "rsvp_deadline"
    t.integer "venue_id"
    t.integer "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "custom_questions"
    t.string "slug"
    t.boolean "public_rsvp_enabled", default: false
    t.index ["slug"], name: "index_events_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.string "company"
    t.boolean "text_capable", default: false
    t.integer "role", default: 0
    t.datetime "registered_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vendor_events", force: :cascade do |t|
    t.integer "vendor_id", null: false
    t.integer "event_id", null: false
    t.text "metadata", default: "{}", null: false
    t.string "qr_token", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "display_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category", default: 0, null: false
    t.index ["category"], name: "index_vendor_events_on_category"
    t.index ["event_id"], name: "index_vendor_events_on_event_id"
    t.index ["qr_token"], name: "index_vendor_events_on_qr_token", unique: true
    t.index ["vendor_id", "event_id"], name: "index_vendor_events_on_vendor_id_and_event_id", unique: true
    t.index ["vendor_id"], name: "index_vendor_events_on_vendor_id"
  end

  create_table "vendor_opt_ins", force: :cascade do |t|
    t.integer "vendor_event_id", null: false
    t.integer "con_opt_in_id", null: false
    t.datetime "scanned_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["con_opt_in_id"], name: "index_vendor_opt_ins_on_con_opt_in_id"
    t.index ["vendor_event_id", "con_opt_in_id"], name: "index_vendor_opt_ins_on_vendor_event_id_and_con_opt_in_id", unique: true
    t.index ["vendor_event_id"], name: "index_vendor_opt_ins_on_vendor_event_id"
  end

  create_table "vendor_users", force: :cascade do |t|
    t.integer "vendor_id", null: false
    t.integer "user_id", null: false
    t.datetime "added_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vendor_users_on_user_id"
    t.index ["vendor_id", "user_id"], name: "index_vendor_users_on_vendor_id_and_user_id", unique: true
    t.index ["vendor_id"], name: "index_vendor_users_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "hook_line"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "participant_type", default: 0, null: false
    t.string "instagram_handle"
    t.string "twitter_handle"
    t.string "tiktok_handle"
    t.index ["participant_type"], name: "index_vendors_on_participant_type"
    t.index ["user_id"], name: "index_vendors_on_user_id"
  end

  create_table "venues", force: :cascade do |t|
    t.string "name"
    t.text "address"
    t.text "description"
    t.integer "capacity"
    t.text "contact_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "broadcast_receipts", "broadcasts"
  add_foreign_key "broadcast_receipts", "con_opt_ins"
  add_foreign_key "broadcasts", "vendor_events"
  add_foreign_key "con_opt_ins", "events"
  add_foreign_key "con_opt_ins", "users"
  add_foreign_key "con_opt_ins", "vendor_events"
  add_foreign_key "event_participants", "events"
  add_foreign_key "event_participants", "users"
  add_foreign_key "event_participants", "users", column: "checked_in_by_id"
  add_foreign_key "vendor_events", "events"
  add_foreign_key "vendor_events", "vendors"
  add_foreign_key "vendor_opt_ins", "con_opt_ins"
  add_foreign_key "vendor_opt_ins", "vendor_events"
  add_foreign_key "vendor_users", "users"
  add_foreign_key "vendor_users", "vendors"
  add_foreign_key "vendors", "users"
end
