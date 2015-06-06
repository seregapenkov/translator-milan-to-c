# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20131213124156) do

  create_table "errors", force: true do |t|
    t.integer  "translation_id"
    t.string   "discription"
    t.integer  "string_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lexems", force: true do |t|
    t.integer  "translation_id"
    t.string   "lexema"
    t.integer  "first_index"
    t.integer  "second_index"
    t.integer  "index_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "numbers", force: true do |t|
    t.integer  "translation_id"
    t.string   "number"
    t.integer  "first_index"
    t.integer  "second_index"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reservedkeywords", force: true do |t|
    t.text     "keywords"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reservedsymbols", force: true do |t|
    t.text     "symbols"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "syntexes", force: true do |t|
    t.integer  "translation_id"
    t.string   "rule"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", force: true do |t|
    t.string   "name"
    t.string   "inprogram"
    t.string   "outprogram"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translationstrings", force: true do |t|
    t.integer  "translation_id"
    t.string   "translationstring"
    t.integer  "first_index"
    t.integer  "second_index"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variables", force: true do |t|
    t.integer  "translation_id"
    t.string   "variable"
    t.integer  "first_index"
    t.integer  "second_index"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
