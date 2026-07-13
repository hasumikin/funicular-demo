class ChannelListComponent < Funicular::Component
  styles do |css|
    css.define :sidebar, "w-64 bg-gray-800 text-white flex flex-col"

    css.define :sidebar_header, "p-4 bg-gray-900"
    css.define :sidebar_title, "text-xl font-bold"
    css.define :settings_button, "text-gray-400 hover:text-white cursor-pointer"
    css.define :channels_list, "flex-1 overflow-y-auto"

    css.define :channel_item, base: "p-4 hover:bg-gray-700 cursor-pointer",
                              active: "bg-gray-700"
    css.define :channel_name, "font-semibold"
    css.define :channel_desc, "text-sm text-gray-400 truncate"

    css.define :user_info, "p-4 bg-gray-900 border-t border-gray-700"
    css.define :user_row, "flex items-start justify-between gap-3"
    css.define :user_identity, "min-w-0"
    css.define :user_name, "text-sm font-semibold"
    css.define :user_handle, "text-xs text-gray-400"
    css.define :blog_link, "mt-2 inline-block text-sm text-blue-400 hover:text-blue-300 cursor-pointer"
    css.define :logout_button, "mt-2 text-sm text-red-400 hover:text-red-300 cursor-pointer"
  end

  def render(h)
    h.div(class: h.styles[:sidebar]) do
      h.div(class: h.styles[:sidebar_header]) do
        h.h2(class: h.styles[:sidebar_title]) { "Channels" }
      end

      h.div(class: h.styles[:channels_list]) do
        props[:channels].each do |channel|
          is_active = props[:current_channel] && props[:current_channel].id == channel.id
          h.div(key: channel.id, class: h.styles[:channel_item, is_active], onclick: -> { props[:on_select_channel].call(channel) }) do
            h.div(class: h.styles[:channel_name]) { "# #{channel.name}" }
            h.div(class: h.styles[:channel_desc]) { channel.description }
          end
        end
      end

      if props[:current_user]
        h.div(class: h.styles[:user_info]) do
          h.div(class: h.styles[:user_row]) do
            h.div(class: h.styles[:user_identity]) do
              h.div(class: h.styles[:user_name]) { props[:current_user].display_name }
              h.div(class: h.styles[:user_handle]) { "@#{props[:current_user].username}" }
            end
            h.link_to h.routes.settings_path, navigate: true, class: h.styles[:settings_button] do
              h.span { "⚙️" }
            end
          end
          h.div do
            h.link_to "/blog", navigate: true, class: h.styles[:blog_link] do
              h.span { "Read our blog" }
            end
          end
          h.button(onclick: props[:on_logout], class: h.styles[:logout_button]) do
            h.span { "Logout" }
          end
        end
      end
    end
  end
end
