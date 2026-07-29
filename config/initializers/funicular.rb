# frozen_string_literal: true

# Exclude app/funicular from autoloading (PicoRuby.wasm code, not for CRuby)
Rails.autoloaders.main.ignore(Rails.root.join("app/funicular"))

# Choose where picoruby_include_tag loads PicoRuby.wasm from, per environment.
#
# Available sources:
#   :local_debug - public/picoruby/debug/init.iife.js (debug build, larger, with symbols)
#   :local_dist  - public/picoruby/dist/init.iife.js  (production build, smaller)
#   :cdn         - https://cdn.jsdelivr.net/npm/@picoruby/wasm-wasi@<version>/dist/init.iife.js
#
# Defaults:
#   development -> :local_debug
#   test        -> :local_debug
#   production  -> :local_dist
#
# Funicular.configure do |config|
#   config.production_source = :cdn
#   # config.cdn_version = "4.0.0"  # defaults to the version vendored in the gem
# end

# Local database (SQLite in the browser): explicit global opt-in.
# user_key isolates each user's IndexedDB snapshots, Web Lock, and
# session epoch; it resolves nil while signed out (anonymous namespace).
Funicular.configure do |config|
  config.local_database = true
  # The signed-in user id straight from the session: the same source
  # current_user reads, without a per-request DB query (the resolver
  # runs on every action for epoch stamping). request.session rather
  # than the controller's session accessor, which an action named
  # "session" would shadow.
  config.user_key = ->(controller) { controller.request.session[:user_id]&.to_s }
end
