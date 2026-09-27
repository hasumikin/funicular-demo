class ChatComponent < Funicular::Component
  styles do
    # Fills the outlet of AppLayoutComponent, which owns the viewport height.
    layout "flex h-full bg-gray-100"
    main_content "flex-1 flex"
  end

  def initialize(params = {})
    super
    @requested_channel_id = params[:channel_id]&.to_i
  end

  def initialize_state
    {
      channels: [],
      current_channel: nil,
      messages: [],
      current_user: nil,
      loading: true,
      skip_scroll: false,
      avatar_cache_buster: Time.now.to_i
    }
  end

  def component_mounted
    # Local-database reactivity: the channel list renders from the
    # replica table. A previous visit's snapshot paints it instantly on
    # reload; Channel.all below revalidates through fetch-through and
    # the watcher re-renders on the change event.
    watch(:channels) { Channel.local.order(:name) }

    # Check if logged in using Session model
    Session.current_user do |user, error|
      if error
        Funicular.router.navigate("/login")
      else
        patch(current_user: user)
        load_channels
      end
    end
  end

  def component_will_unmount
    @subscription.unsubscribe if @subscription
  end

  def load_channels
    # Explicit fetch (the framework never fetches implicitly): the
    # response upserts the replica table, and the watch above updates
    # state[:channels] -- no manual patch of the list here.
    Channel.all do |channels, error|
      if error
        # Silent-empty sidebars are undebuggable: say why the fetch
        # failed. The watch keeps rendering whatever the replica holds.
        puts "[demo] Channel.all failed: #{error}"
        patch(loading: false)
      else
        patch(loading: false)
        if channels.size > 0 && !state[:current_channel]
          # Select requested channel if specified, otherwise select first channel
          if @requested_channel_id
            selected_channel = channels.find { |ch| ch.id == @requested_channel_id }
            select_channel(selected_channel) if selected_channel
          else
            select_channel(channels[0])
          end
        end
      end
    end
  end

  def select_channel(channel)
    patch(current_channel: channel, messages: [], loading: true)

    # Update URL to reflect the current channel
    new_path = "/chat/#{channel.id}"
    if Funicular.router.current_location_path != new_path
      JS.global.history.replaceState(JS::Bridge.to_js({}), '', new_path)
    end

    # Subscribe to ActionCable channel
    if @subscription
      @subscription.unsubscribe
    end

    consumer = Funicular::Cable.create_consumer("/cable")
    @subscription = consumer.subscriptions.create(
      { channel: "ChatChannel", channel_id: channel.id }
    ) do |data|
      case data["type"]
      when "initial_messages"
        patch(messages: data["messages"], loading: false)
      when "new_message"
        messages = state[:messages] + [data["message"]]
        patch(messages: messages, skip_scroll: false)
      when "delete_message"
        handle_message_delete(data["message_id"])
      end
    end
  end

  def handle_send_message(content)
    return if content.to_s.strip.empty?
    return unless @subscription

    @subscription.perform("send_message", { content: content })
  end

  def handle_message_delete(message_id)
    remove_via(
      "message-#{message_id}",
      "opacity-100 max-h-screen", "opacity-0 max-h-0",
      duration: 500,
    ) do
      updated_messages = state[:messages].reject { |m| m["id"] == message_id }
      patch(messages: updated_messages, skip_scroll: true)
    end
  end

  def render
    div(class: styles.layout) do
      # Sidebar - Channel list
      component(ChannelListComponent, {
        preserve: true,
        channels: state[:channels],
        current_channel: state[:current_channel],
        current_user: state[:current_user],
        on_select_channel: ->(channel) { select_channel(channel) }
      })

      # Main content area (chat + stats)
      div(class: styles.main_content) do
        # Chat area
        component(MessageListComponent, {
          preserve: true,
          current_channel: state[:current_channel],
          channel_id: state[:current_channel]&.id,
          messages: state[:messages],
          loading: state[:loading],
          current_user: state[:current_user],
          skip_scroll: state[:skip_scroll],
          avatar_cache_buster: state[:avatar_cache_buster],
          on_send_message: ->(content) { handle_send_message(content) },
          on_message_delete: ->(message_id) { handle_message_delete(message_id) }
        })
      end
    end
  end
end
