class MessageListComponent < Funicular::Component
  styles do |css|
    css.define :chat_container, "flex-1 flex flex-col"
    css.define :chat_header, "bg-white border-b border-gray-200 p-4"
    css.define :chat_title, "text-xl font-bold text-gray-800"
    css.define :chat_subtitle, "text-sm text-gray-600"

    css.define :messages_area, "flex-1 overflow-y-auto p-4 space-y-4"
    css.define :loading, "text-center text-gray-500"

    css.define :empty_state, "flex-1 flex items-center justify-center text-gray-500"
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

  def render(h)
    h.div(class: h.styles[:chat_container]) do
      if props[:current_channel]
        # Chat header
        h.div(class: h.styles[:chat_header]) do
          h.h3(class: h.styles[:chat_title]) { "# #{props[:current_channel].name}" }
          h.div(class: h.styles[:chat_subtitle]) { props[:current_channel].description }
        end

        # Messages area
        h.div(ref: :messages_container, class: h.styles[:messages_area]) do
          if props[:loading]
            h.div(class: h.styles[:loading]) { "Loading messages..." }
          else
            props[:messages].each do |message|
              h.component(MessageComponent, {
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
        h.component(MessageInputComponent, {
          preserve: true,
          channel_id: props[:channel_id],
          on_send_message: props[:on_send_message]
        })
      else
        h.div(class: h.styles[:empty_state]) do
          h.span { "Select a channel to start chatting" }
        end
      end
    end
  end
end
