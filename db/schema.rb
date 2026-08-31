ActiveRecord::Schema[8.0].define(version: 2024_01_01_000000) do
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.string   "email",      null: false
    t.string   "username",   null: false
    t.string   "name",       null: false
    t.string   "password_digest"
    t.timestamps
    t.index ["email"],    name: "index_users_on_email",    unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint   "user_id",              null: false
    t.string   "vehicle_type",         null: false, default: "motorcycle"
    t.string   "brand",                null: false
    t.string   "model",                null: false
    t.integer  "model_year"
    t.string   "nickname"
    t.string   "registration_number"
    t.string   "display_name"
    t.boolean  "in_use",               default: false
    t.timestamps
    t.index ["user_id"], name: "index_vehicles_on_user_id"
  end

  create_table "rides", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "status",     null: false, default: "draft"
    t.string   "public_id",  null: false
    t.bigint   "leader_id",  null: false
    t.text     "description"
    t.boolean  "auto_approve", default: false
    t.timestamps
    t.index ["public_id"],  name: "index_rides_on_public_id", unique: true
    t.index ["leader_id"],  name: "index_rides_on_leader_id"
  end

  create_table "ride_memberships", force: :cascade do |t|
    t.bigint   "ride_id",    null: false
    t.bigint   "user_id",    null: false
    t.bigint   "vehicle_id"
    t.string   "role",       null: false, default: "rider"
    t.string   "status",     null: false, default: "pending"
    t.timestamps
    t.index ["ride_id"], name: "index_ride_memberships_on_ride_id"
    t.index ["user_id"], name: "index_ride_memberships_on_user_id"
  end

  create_table "ride_locations", force: :cascade do |t|
    t.bigint   "ride_id",      null: false
    t.bigint   "user_id",      null: false
    t.float    "latitude",     null: false
    t.float    "longitude",    null: false
    t.float    "altitude"
    t.float    "speed"
    t.float    "heading"
    t.float    "accuracy"
    t.string   "rider_status", null: false, default: "riding"
    t.string   "gps_state",    default: "good"
    t.string   "network_state", default: "online"
    t.integer  "battery_level"
    t.datetime "recorded_at",  null: false
    t.timestamps
    t.index ["ride_id", "user_id"], name: "index_ride_locations_on_ride_id_and_user_id", unique: true
  end

  create_table "ride_track_points", force: :cascade do |t|
    t.bigint   "ride_id",      null: false
    t.bigint   "user_id",      null: false
    t.float    "latitude",     null: false
    t.float    "longitude",    null: false
    t.float    "altitude"
    t.float    "speed"
    t.float    "heading"
    t.float    "accuracy"
    t.string   "rider_status"
    t.integer  "battery_level"
    t.string   "gps_state"
    t.string   "network_state"
    t.datetime "recorded_at",  null: false
    t.timestamps
    t.index ["ride_id", "user_id"], name: "index_ride_track_points_on_ride_and_user"
  end

  create_table "emergency_events", force: :cascade do |t|
    t.bigint   "ride_id",         null: false
    t.bigint   "user_id",         null: false
    t.bigint   "resolved_by_id"
    t.string   "event_type",      null: false, default: "sos"
    t.string   "sub_type"
    t.text     "notes"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "resolved_at"
    t.timestamps
    t.index ["ride_id"], name: "index_emergency_events_on_ride_id"
    t.index ["user_id"], name: "index_emergency_events_on_user_id"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint   "user_id",     null: false
    t.string   "push_token",  null: false
    t.string   "platform",    default: "android"
    t.timestamps
    t.index ["user_id"],     name: "index_devices_on_user_id"
    t.index ["push_token"],  name: "index_devices_on_push_token", unique: true
  end

  add_foreign_key "vehicles",         "users"
  add_foreign_key "rides",            "users", column: "leader_id"
  add_foreign_key "ride_memberships", "rides"
  add_foreign_key "ride_memberships", "users"
  add_foreign_key "ride_locations",   "rides"
  add_foreign_key "ride_locations",   "users"
  add_foreign_key "ride_track_points","rides"
  add_foreign_key "ride_track_points","users"
  add_foreign_key "emergency_events", "rides"
  add_foreign_key "emergency_events", "users"
  add_foreign_key "devices",          "users"
end
