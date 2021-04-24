# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_11_12_080414) do

  create_table "companies", force: :cascade do |t|
    t.boolean "available", default: false, null: false
    t.string "note", limit: 256
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "address"
    t.string "code", null: false
    t.string "slug", null: false
    t.integer "company_id", limit: 8, null: false
    t.integer "country_id", null: false
    t.integer "invitable_id", null: false
    t.string "invitable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone", "slug"], name: "index_users_on_phone_and_slug"
    t.index ["phone"], name: "index_users_on_phone"
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

end
