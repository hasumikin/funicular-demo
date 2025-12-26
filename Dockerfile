# Stage 1: Build environment
FROM ruby:4.0-slim AS builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libsqlite3-dev \
    libyaml-dev \
    pkg-config \
    curl \
    nodejs \
    npm && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

# Build picorbc compiler
WORKDIR /tmp/picoruby
RUN git clone --depth=1 --single-branch --branch master https://github.com/picoruby/picoruby . && \
    git submodule update --init --recursive mrbgems/mruby-compiler2 && \
    git submodule update --init mrbgems/mruby-bin-mrbc2 && \
    MRUBY_CONFIG=picorbc rake && \
    cp bin/picorbc /usr/local/bin/ && \
    chmod +x /usr/local/bin/picorbc

WORKDIR /rails

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'test' && \
    bundle install

# Copy application code
COPY . .

# Compile PicoRuby code with funicular
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails funicular:compile

# Precompile assets
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile
RUN bundle exec rails tailwindcss:build

# Stage 2: Runtime environment
FROM ruby:4.0-slim

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r rails && useradd -r -g rails rails

WORKDIR /rails

# Copy built artifacts from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /rails /rails

# Create storage and log directories
RUN mkdir -p /rails/storage /rails/log && \
    chown -R rails:rails /rails

USER rails:rails

EXPOSE 80

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    PORT=80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD curl -f http://localhost:80/up || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
