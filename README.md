# Funicular Demo

Canonical demo application for [Funicular](https://picoruby.org/funicular-on-rails), a Rails-integrated SPA framework that runs client-side Ruby on PicoRuby.wasm.

The app is a Slack-like chat application because chat is a useful stress case for a Rails frontend: it needs routing, realtime updates, optimistic-feeling input, local drafts, settings, file upload, reusable plugins, and component tests.

## Why This Demo Exists

Most Rails applications should start with Hotwire. Turbo and Stimulus are a good default when the browser mostly displays server-rendered HTML and sends small interactions back to Rails.

Funicular is for the part of a Rails app that has become a real client-side application:

- stateful component trees
- client-side routing between app screens
- realtime ActionCable subscriptions
- local browser state such as draft messages
- reusable client-side components and plugins
- client-side tests that run with the Rails test suite

The point is not to replace Hotwire across a whole application. The point is to keep writing Ruby when one interactive area would otherwise pull in a JavaScript SPA stack.

## What The Demo Shows

- **Chat UI**: channel list, message list, message input, settings navigation, and client-side routing under `app/funicular/components/`.
- **Realtime updates**: ActionCable broadcasts from Rails controllers/channels into Funicular components.
- **Local drafts**: unsent messages are stored with the Funicular IndexedDB-backed store.
- **Rails model integration**: Funicular models load schemas from Rails and use Rails-style endpoints.
- **Plugins**: settings uses `funicular-datepicker` and `funicular-image-uploader`.
- **Image upload**: profile images are selected and previewed in Funicular, then uploaded to a Rails endpoint.
- **SSR and hydration**: the public blog routes are server-rendered by Rails and hydrated by Funicular.
- **Client tests**: `*_picotest.rb` component tests run from normal Rails Minitest.

## Hotwire vs Funicular In This App

With Hotwire, a chat UI often starts cleanly: render messages on the server, stream updates with Turbo Streams, and use a little Stimulus for input behavior. That remains a good approach for many products.

This demo intentionally goes past that line. It keeps channel state, draft state, current route, component state, plugin state, and realtime updates on the client. In that shape, Funicular gives Rails developers a single Ruby code path for the interactive surface while Rails still owns persistence, authentication, routing fallback, ActionCable, and server-rendered public pages.

## Run It

```bash
bundle install
npm install
bin/rails db:setup
bin/rails funicular:install
bin/rails server
```

Then open:

- `http://localhost:3000/chat`
- `http://localhost:3000/settings`
- `http://localhost:3000/blog`

## Tests

Run the full Rails test suite:

```bash
bin/rails test
```

Run only the Funicular client test wrapper:

```bash
bin/rails test test/funicular/application_test.rb
```

Client-side component tests live under `test/funicular/client/**/*_picotest.rb`.

## Key Files

- `app/funicular/initializer.rb`: Funicular startup, schema loading, routes, store setup.
- `app/funicular/components/chat_component.rb`: top-level chat screen.
- `app/funicular/components/settings_component.rb`: plugin-backed settings screen.
- `app/funicular/stores/draft_store.rb`: IndexedDB-backed draft messages.
- `app/channels/chat_channel.rb`: ActionCable integration.
- `app/controllers/home_controller.rb`: SSR entry point for the blog.
- `test/funicular/application_test.rb`: Rails wrapper for Funicular client tests.
