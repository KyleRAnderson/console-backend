# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_26_134531) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "hunts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "roster_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "current_match_id", default: 0, null: false
    t.index ["roster_id"], name: "index_hunts_on_roster_id"
  end

  create_table "licenses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "eliminated", default: false, null: false
    t.uuid "hunt_id", null: false
    t.uuid "participant_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hunt_id"], name: "index_licenses_on_hunt_id"
    t.index ["participant_id"], name: "index_licenses_on_participant_id"
  end

  create_table "licenses_matches", id: false, force: :cascade do |t|
    t.uuid "license_id", null: false
    t.uuid "match_id", null: false
    t.index ["license_id"], name: "index_licenses_matches_on_license_id"
    t.index ["match_id"], name: "index_licenses_matches_on_match_id"
  end

  create_table "matches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "round_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "local_id", null: false
    t.index ["local_id"], name: "index_matches_on_local_id"
    t.index ["round_id"], name: "index_matches_on_round_id"
  end

  create_table "participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "first"
    t.string "last"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "roster_id"
    t.jsonb "extras", default: {}, null: false
    t.index ["roster_id"], name: "index_participants_on_roster_id"
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "level", default: 0, null: false
    t.uuid "user_id", null: false
    t.uuid "roster_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id", "roster_id"], name: "index_permissions_on_user_id_and_roster_id", unique: true
  end

  create_table "rosters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "participant_properties"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "rounds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "hunt_id", null: false
    t.integer "number", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hunt_id"], name: "index_rounds_on_hunt_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "hunts", "rosters"
  add_foreign_key "licenses", "hunts"
  add_foreign_key "licenses", "participants"
  add_foreign_key "licenses_matches", "licenses"
  add_foreign_key "licenses_matches", "matches"
  add_foreign_key "matches", "rounds"
  add_foreign_key "participants", "rosters"
  add_foreign_key "permissions", "rosters"
  add_foreign_key "permissions", "users"
  add_foreign_key "rounds", "hunts"
end
