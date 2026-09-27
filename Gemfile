source "https://rubygems.org"

gem "rails", "~> 8.1.1"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"

# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Tailwind CSS
gem "tailwindcss-rails"

# Router layouts need funicular 0.5.2, which is not on RubyGems yet.
# Switch back to `gem "funicular"` once 0.5.2 ships.
gem "funicular", github: "picoruby/funicular", ref: "fcc0030b6222528ef4ca39d4c74c772666723ac5"

group :funicular do
  gem "funicular-datepicker"
  gem "funicular-image-uploader"
end

group :development do
  gem "debug", platforms: %i[ mri windows ]
  gem "web-console"
  gem "katakata_irb"
  gem "repl_type_completor"
end
