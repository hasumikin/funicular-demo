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

puts "Seed data created successfully!"
puts "Users: #{User.count}"
puts "Channels: #{Channel.count}"
puts "Messages: #{Message.count}"
