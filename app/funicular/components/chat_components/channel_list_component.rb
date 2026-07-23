class ChannelListComponent < Funicular::Component
  styles do
    sidebar "w-64 bg-gray-800 text-white flex flex-col"

    sidebar_header "p-4 bg-gray-900"
    sidebar_title "text-xl font-bold"
    settings_button "text-gray-400 hover:text-white cursor-pointer"
    channels_list "flex-1 overflow-y-auto"

    channel_item base: "p-4 hover:bg-gray-700 cursor-pointer",
                 active: "bg-gray-700"
    channel_name "font-semibold"
    channel_desc "text-sm text-gray-400 truncate"

    user_info "p-4 bg-gray-900 border-t border-gray-700"
    user_row "flex items-start justify-between gap-3"
    user_identity "min-w-0"
    user_name "text-sm font-semibold"
    user_handle "text-xs text-gray-400"
    blog_link "mt-2 inline-block text-sm text-blue-400 hover:text-blue-300 cursor-pointer"
    logout_button "mt-2 text-sm text-red-400 hover:text-red-300 cursor-pointer"
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

      if props[:current_user]
        div(class: styles.user_info) do
          div(class: styles.user_row) do
            div(class: styles.user_identity) do
              div(class: styles.user_name) { props[:current_user].display_name }
              div(class: styles.user_handle) { "@#{props[:current_user].username}" }
            end
            link_to routes.settings_path, navigate: true, class: styles.settings_button do
              span { "⚙️" }
            end
          end
          div do
            link_to "/blog", navigate: true, class: styles.blog_link do
              span { "Read our blog" }
            end
          end
          button(onclick: props[:on_logout], class: styles.logout_button) do
            span { "Logout" }
          end
        end
      end
    end
  end
end
