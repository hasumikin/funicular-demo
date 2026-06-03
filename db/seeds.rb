# Create demo users
joker = User.find_or_create_by!(username: "joker") do |u|
  u.password = "password"
  u.display_name = "joker1007"
end

yancya = User.find_or_create_by!(username: "yancya") do |u|
  u.password = "password"
  u.display_name = "yancya"
end

hasumikin = User.find_or_create_by!(username: "hasumikin") do |u|
  u.password = "password"
  u.display_name = "L-chika"
end

# Create demo channels
general = Channel.find_or_create_by!(name: "general") do |c|
  c.description = "General discussion for everyone"
end

random = Channel.find_or_create_by!(name: "random") do |c|
  c.description = "Random chat and off-topic discussions"
end

tech = Channel.find_or_create_by!(name: "tech") do |c|
  c.description = "Technology and programming discussions"
end

# Create some sample messages
if Message.count == 0
  Message.create!([
    # general
    { user: hasumikin, channel: general, content: "Welcome to the demo! This chat is powered by Funicular." },
    { user: joker,     channel: general, content: "Is this running on Funicular? Let me check the source." },
    { user: yancya,    channel: general, content: "Typed this on my ErgoDox. Already feels productive." },
    { user: hasumikin, channel: general, content: "Yes! Funicular uses PicoRuby under the hood." },
    { user: joker,     channel: general, content: "Interesting. How does it handle reconnection?" },
    { user: yancya,    channel: general, content: "According to the README, it does exponential backoff." },
    { user: hasumikin, channel: general, content: "Exactly. And it works on microcontrollers too!" },
    { user: joker,     channel: general, content: "Sure it does." },

    # tech
    { user: joker,     channel: tech, content: "Please tell me there are no N+1 queries lurking in this app." },
    { user: yancya,    channel: tech, content: "Already ran EXPLAIN ANALYZE. Composite index on channel_id and created_at. Clean." },
    { user: joker,     channel: tech, content: "Good. I have seen too many chat apps melt under load because of lazy loading." },
    { user: hasumikin, channel: tech, content: "I want to run this entire chat app on a Raspberry Pi Pico someday." },
    { user: joker,     channel: tech, content: "That would be cursed. I love it." },
    { user: yancya,    channel: tech, content: "The schema is pretty straightforward. users, channels, messages. No surprises." },
    { user: joker,     channel: tech, content: "Famous last words." },
    { user: hasumikin, channel: tech, content: "PicoRuby can run mruby bytecode directly on the RP2040 chip." },
    { user: yancya,    channel: tech, content: "So theoretically this WebSocket client could live on the microcontroller side?" },
    { user: hasumikin, channel: tech, content: "That is the dream, yes." },
    { user: joker,     channel: tech, content: "Someone is going to do this and it will break production at 3am." },
    { user: yancya,    channel: tech, content: "Elixir has had great primitives for this kind of pub/sub forever. Good to see Ruby catching up." },
    { user: joker,     channel: tech, content: "Ruby does not need to catch up. It needs to do it in Ruby." },

    # random
    { user: joker,     channel: random, content: "Eating Alfort while watching the talk. Peak RubyKaigi experience." },
    { user: yancya,    channel: random, content: "ErgoDox or HHKB? I will die on this hill." },
    { user: hasumikin, channel: random, content: "L-chika is the Hello World of hardware. Change my mind." },
    { user: joker,     channel: random, content: "Alfort is objectively the best chocolate biscuit. This is not up for debate." },
    { user: yancya,    channel: random, content: "Columbo is also fine." },
    { user: joker,     channel: random, content: "Absolutely not." },
    { user: hasumikin, channel: random, content: "I once made a keyboard firmware in Ruby. It runs on RP2040." },
    { user: yancya,    channel: random, content: "PRK Firmware right? I have been meaning to build one." },
    { user: hasumikin, channel: random, content: "Do it. Soldering is the easy part. Trust me." },
    { user: joker,     channel: random, content: "I will stick to software. Electrons are not my domain." }
  ])
end

# Create blog posts (authored by a fictional admin; no admin UI exists).
# These are read from the DB and server-rendered on the public /blog pages.
blog_author = "Funicular Team"

intro = Post.find_or_create_by!(title: "Why we built this chat on Funicular") do |p|
  p.author_name = blog_author
  p.published_at = Time.utc(2026, 1, 12, 9, 0, 0)
  p.body = <<~BODY.strip
    This chat app is a demo for Funicular, a Ruby-first frontend framework that
    runs your component code as PicoRuby in the browser via WebAssembly. The same
    component classes you write for the client also run on the server under CRuby,
    which is what makes server-side rendering possible without a second codebase.

    The chat itself is a single-page application: channels, messages and presence
    are all driven by Ruby components talking to Rails over Action Cable. No
    JavaScript was written by hand to build it.
  BODY
end

ssr_post = Post.find_or_create_by!(title: "Server-side rendering and hydration, in Ruby") do |p|
  p.author_name = blog_author
  p.published_at = Time.utc(2026, 2, 3, 9, 0, 0)
  p.body = <<~BODY.strip
    A component's render method is just pure Ruby that returns a virtual DOM tree.
    On the server we walk that tree and serialize it to an HTML string, inject the
    same data as window state, and send data-filled markup to the browser. You get
    a fast first paint and real content in "View Source" for search engines.

    In the browser the same component hydrates that markup: it rebuilds the virtual
    DOM from the injected state and attaches event listeners to the existing nodes
    instead of rebuilding them. From there it behaves like a normal SPA. This very
    blog page is server-rendered and then hydrated.
  BODY
end

pico_post = Post.find_or_create_by!(title: "PicoRuby: Ruby small enough for a microcontroller") do |p|
  p.author_name = blog_author
  p.published_at = Time.utc(2026, 3, 18, 9, 0, 0)
  p.body = <<~BODY.strip
    PicoRuby is a compact mruby implementation that runs on devices as small as
    the RP2040. The same runtime, compiled to WebAssembly, is what powers Funicular
    in the browser. Being able to run Ruby in such constrained environments is what
    keeps the framework small and fast to start.

    Our long-term dream is cursed and wonderful: run a meaningful slice of this chat
    client on an actual microcontroller. We are not there yet, but the pieces exist.
  BODY
end

# Seed a few comments so anonymous visitors see real threads (also SSR'd).
if Comment.count == 0
  Comment.create!([
    { post: intro,     user: joker,     body: "No hand-written JS at all? I need to read the source to believe it." },
    { post: intro,     user: yancya,    body: "The Action Cable wiring is clean. Nicely done." },
    { post: ssr_post,  user: hasumikin, body: "Hydration matching the server output is the tricky part. Glad it just works." },
    { post: ssr_post,  user: joker,     body: "View Source actually shows the article text. Respect." },
    { post: pico_post, user: yancya,    body: "Running this on an RP2040 would be gloriously cursed." },
    { post: pico_post, user: hasumikin, body: "Give me time. Soldering is the easy part." }
  ])
end

puts "Seed data created successfully!"
puts "Users: #{User.count}"
puts "Channels: #{Channel.count}"
puts "Messages: #{Message.count}"
puts "Posts: #{Post.count}"
puts "Comments: #{Comment.count}"
