class ChannelListComponent < Funicular::Component
  styles do
    sidebar "w-64 bg-gray-800 text-white flex flex-col"

    sidebar_header "p-4 bg-gray-900"
    sidebar_title "text-xl font-bold"
    channels_list "flex-1 overflow-y-auto"

    channel_item base: "p-4 hover:bg-gray-700 cursor-pointer",
                 active: "bg-gray-700"
    channel_name "font-semibold"
    channel_desc "text-sm text-gray-400 truncate"

    user_info "p-4 bg-gray-900 border-t border-gray-700"
    user_name "text-sm font-semibold"
    user_handle "text-xs text-gray-400"
  end

  def render
    div(class: styles.sidebar) do
      div(class: styles.sidebar_header) do
        h2(class: styles.sidebar_title) { "Channels" }
      end

      div(class: styles.channels_list) do
        props[:channels].each do |channel|
          is_active = props[:current_channel] && props[:current_channel].id == channel.id
          div(key: channel.id, class: styles.channel_item(is_active), onclick: -> { props[:on_select_channel].call(channel) }) do
            div(class: styles.channel_name) { "# #{channel.name}" }
            div(class: styles.channel_desc) { channel.description }
          end
        end
      end

      # Settings, blog, and logout live in AppLayoutComponent's top bar.
      if props[:current_user]
        div(class: styles.user_info) do
          div(class: styles.user_name) { props[:current_user].display_name }
          div(class: styles.user_handle) { "@#{props[:current_user].username}" }
        end
      end
    end
  end
end
