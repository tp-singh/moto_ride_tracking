# ── Stage 1: builder ─────────────────────────────────────────────────────────
FROM ruby:3.3.0-slim AS builder

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler:2.5.4 --no-document

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_FORCE_RUBY_PLATFORM=1

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN bundle exec bootsnap precompile --gemfile app/ lib/

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM ruby:3.3.0-slim AS runtime

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

RUN groupadd --gid 1001 app && \
    useradd --uid 1001 --gid app --shell /bin/bash --create-home app && \
    chown -R app:app /app /usr/local/bundle

USER app

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_FORCE_RUBY_PLATFORM=1

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
