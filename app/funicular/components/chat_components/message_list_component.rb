class MessageListComponent < Funicular::Component
  styles do
    chat_container "flex-1 flex flex-col"
    chat_header "bg-white border-b border-gray-200 p-4"
    chat_title "text-xl font-bold text-gray-800"
    chat_subtitle "text-sm text-gray-600"

    messages_area "flex-1 overflow-y-auto p-4 space-y-4"
    loading "text-center text-gray-500"

    empty_state "flex-1 flex items-center justify-center text-gray-500"
  end

  def component_updated
    return if props[:skip_scroll]
    scroll_to_bottom if props[:messages] && !props[:messages].empty?
  end

  def scroll_to_bottom
    sleep_ms 100
    if @refs[:messages_container]
      container = @refs[:messages_container]
      container[:scrollTop] = container[:scrollHeight]
    end
  end

  def render
    div(class: s.chat_container) do
      if props[:current_channel]
        # Chat header
        div(class: s.chat_header) do
          h3(class: s.chat_title) { "# #{props[:current_channel].name}" }
          div(class: s.chat_subtitle) { props[:current_channel].description }
        end

        # Messages area
        div(ref: :messages_container, class: s.messages_area) do
          if props[:loading]
            div(class: s.loading) { "Loading messages..." }
          else
            props[:messages].each do |message|
              component(MessageComponent, {
                key: message["id"],
                preserve: true,
                message: message,
                current_user: props[:current_user],
                avatar_cache_buster: props[:avatar_cache_buster],
                on_delete: props[:on_message_delete]
              })
            end
          end
        end

        # Message input (isolated child so typing does not re-render the messages area)
        component(MessageInputComponent, {
          preserve: true,
          on_send_message: props[:on_send_message]
        })
      else
        div(class: s.empty_state) do
          span { "Select a channel to start chatting" }
        end
      end
    end
  end
end
