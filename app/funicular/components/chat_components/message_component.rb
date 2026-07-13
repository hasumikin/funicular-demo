class MessageComponent < Funicular::Component
  styles do |css|
    css.define :message, "flex items-start space-x-3 overflow-hidden transition-[opacity,max-height,transform] duration-500 ease-out max-h-screen"
    css.define :avatar_img, "flex-shrink-0 w-10 h-10 rounded-full object-cover"
    css.define :avatar_placeholder, "flex-shrink-0 w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold"

    css.define :message_content, "flex-1"
    css.define :message_header, "flex items-baseline space-x-2"
    css.define :message_author, "font-semibold text-gray-900"
    css.define :message_time, "text-xs text-gray-500"
    css.define :message_text, "text-gray-800 mt-1"

    css.define :delete_button, "ml-2 text-xs text-red-500 hover:text-red-700 cursor-pointer"
  end

  def component_mounted
    add_via(
      "message-#{props[:message]['id']}",
      "opacity-0 scale-95",
      "opacity-100 scale-100",
      duration: 300
    )
  end

  def render(h)
    h.div(class: "#{h.styles[:message]} opacity-0 scale-95", id: "message-#{props[:message]['id']}") do
      # Avatar
      if props[:message]["user"]["has_avatar"]
        # Add cache buster for current user's avatar to show updates immediately
        is_current_user = props[:current_user] && props[:current_user].id == props[:message]["user"]["id"]
        avatar_url = if is_current_user && props[:avatar_cache_buster]
          "/users/#{props[:message]['user']['id']}/avatar?t=#{props[:avatar_cache_buster]}"
        else
          "/users/#{props[:message]['user']['id']}/avatar"
        end
        h.img(src: avatar_url, class: h.styles[:avatar_img])
      else
        h.div(class: h.styles[:avatar_placeholder]) do
          h.span { props[:message]["user"]["display_name"][0].upcase }
        end
      end

      h.div(class: h.styles[:message_content]) do
        h.div(class: h.styles[:message_header]) do
          h.span(class: h.styles[:message_author]) { props[:message]["user"]["display_name"] }
          h.span(class: h.styles[:message_time]) { props[:message]["created_at"] }

          # Show delete button only for own messages
          if props[:current_user] && props[:current_user].id == props[:message]["user"]["id"]
            h.link_to h.routes.message_path(props[:message]['id']), method: :delete, class: h.styles[:delete_button] do
              h.span { "Delete" }
            end
          end
        end
        h.div(class: h.styles[:message_text]) { props[:message]["content"] }
      end
    end
  end

  # Override handle_link_response to handle successful deletion
  def handle_link_response(response, path, method)
    if method.to_s.downcase.to_sym == :delete && !response.error?
      # Extract message ID from path (e.g., "/messages/123")
      message_id = path.split('/').last.to_i
      # The parent component will receive the delete event via Action Cable
      # and handle the UI update.
      # props[:on_delete].call(message_id) if props[:on_delete]
    end
    super
  end
end
