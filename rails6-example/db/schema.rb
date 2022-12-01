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

ActiveRecord::Schema.define(version: 2021_12_29_101039) do

  create_table "companies", force: :cascade do |t|
    t.boolean "available", default: false, null: false
    t.string "note", limit: 256
    t.string "type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

# Could not dump table "organizations" because of following StandardError
#   Unknown type 'bigserial' for column 'id'

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "address"
    t.string "code", null: false
    t.string "slug", null: false
    t.integer "company_id", limit: 8, null: false
    t.integer "country_id"
    t.integer "organization_id", null: false
    t.integer "invitable_id", null: false
    t.string "invitable_type", null: false
    t.integer "subject_id", null: false
    t.string "subject_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "slug"], name: "index_users_on_name_and_slug", unique: true
    t.index ["phone", "slug"], name: "index_users_on_phone_and_slug"
    t.index ["phone"], name: "index_users_on_phone"
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  add_foreign_key "users", "countries"
end
