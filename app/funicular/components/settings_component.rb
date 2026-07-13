class SettingsComponent < Funicular::Component
  styles do |css|
    css.define :container, "min-h-screen bg-gray-100 py-8"
    css.define :card, "max-w-2xl mx-auto bg-white rounded-lg shadow-md p-8"
    css.define :header, "flex items-center justify-between mb-6"
    css.define :title, "text-2xl font-bold text-gray-800"
    css.define :back_button, "text-blue-600 hover:text-blue-800"
    css.define :message,
               base: "mb-4 p-4 border rounded",
               variants: {
                 success: "bg-green-100 border-green-400 text-green-700",
                 error: "bg-red-100 border-red-400 text-red-700"
               }
    css.define :form, "space-y-6"
    css.define :section, "space-y-3 pb-6 border-b border-gray-200"
    css.define :profile_section, "space-y-6"
    css.define :label, "block text-sm font-medium text-gray-700 mb-2"
    css.define :section_title, "text-lg font-semibold text-gray-800"
    css.define :section_hint, "text-sm text-gray-500"
    css.define :input, "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
    css.define :file_input, "w-full text-sm text-gray-700 cursor-pointer file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:bg-blue-600 file:text-white file:font-semibold file:cursor-pointer hover:file:bg-blue-700"
    css.define :input_disabled, "w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-600"
    css.define :avatar_container, "mb-2"
    css.define :avatar, "w-24 h-24 rounded-full object-cover"
    css.define :loading_container, "flex items-center justify-center py-8"
    css.define :loading_spinner, "animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full"

    css.define :submit_button,
               base: "w-full py-2 px-4 rounded-md transition duration-200 font-semibold",
               variants: {
                 normal: "bg-blue-600 text-white hover:bg-blue-700",
                 saving: "bg-blue-600 text-white hover:bg-blue-700 opacity-50 cursor-not-allowed"
               }
  end

  def initialize_state
    {
      user: { username: "", display_name: "", birthday: "" },
      errors: {},
      message: nil,
      is_error: false,
      saving: false,
      current_user: nil,
      avatar_cache_buster: Time.now.to_i
    }
  end

  def component_mounted
    Session.current_user do |user, error|
      if error
        Funicular.router.navigate("/login")
      else
        patch(
          current_user: user,
          user: {
            username: user.username,
            display_name: user.display_name,
            birthday: user.birthday
          }
        )
      end
    end
  end

  def handle_save(data)
    patch(saving: true, message: nil, is_error: false, errors: {})
    save_with_model(data[:display_name], data[:birthday] || state[:user][:birthday] || state[:user]["birthday"])
  end

  def save_with_model(display_name, birthday)
    # Preserve has_avatar state
    current_user = state[:current_user]
    had_avatar = current_user.has_avatar

    current_user.display_name = display_name
    current_user.birthday = birthday
    current_user.update do |success, result|
      if success
        current_user.instance_variable_set("@display_name", result["display_name"])
        current_user.instance_variable_set("@birthday", result["birthday"])
        # Preserve has_avatar if not included in response
        if result["has_avatar"].nil? && had_avatar
          current_user.instance_variable_set("@has_avatar", true)
        end

        patch(
          current_user: current_user,
          saving: false,
          message: "Settings saved successfully!",
          is_error: false,
          user: {
            username: current_user.username,
            display_name: current_user.display_name,
            birthday: current_user.birthday
          }
        )
      elsif result.respond_to?(:messages)
        # Client-side validation failed before any request: show inline,
        # per-field errors (rendered by form_for beside each field).
        patch(saving: false, errors: result.messages)
      else
        patch(saving: false, message: "Error: #{result}", is_error: true)
      end
    end
  end

  def render(h)
    h.div(class: h.styles[:container]) do
      h.div(class: h.styles[:card]) do
        h.div(class: h.styles[:header]) do
          h.h1(class: h.styles[:title]) { "Settings" }
          h.button(
            onclick: -> { Funicular.router.navigate("/chat") },
            class: h.styles[:back_button]
          ) do
            h.span { "<- Back to Chat" }
          end
        end

        if state[:message]
          h.div(class: h.styles[:message, state[:is_error] ? :error : :success]) do
            h.span { state[:message] }
          end
        end

        h.div do
          current_user = state[:current_user]

          if current_user.nil?
            h.div(class: h.styles[:loading_container]) do
              h.div(class: h.styles[:loading_spinner])
            end
          else
            h.div(class: h.styles[:section]) do
              h.div do
                h.h2(class: h.styles[:section_title]) { "Avatar" }
                h.p(class: h.styles[:section_hint]) { "Image changes are saved immediately." }
              end
              h.component(
                Funicular::Plugins::ImageUploader::Component,
                src: current_user.has_avatar ? "/users/#{current_user.id}/avatar?t=#{state[:avatar_cache_buster]}" : nil,
                upload_url: "/users/#{current_user.id}/avatar",
                input_id: "avatar-input",
                file_field: "avatar",
                auto_upload: true,
                preview_container_class: h.styles[:avatar_container],
                image_class: h.styles[:avatar],
                input_class: h.styles[:file_input],
                on_upload: ->(result) {
                  current_user.instance_variable_set("@has_avatar", true)
                  patch(
                    current_user: current_user,
                    message: "Avatar updated successfully!",
                    is_error: false,
                    avatar_cache_buster: Time.now.to_i
                  )
                },
                on_error: ->(message, result) {
                  patch(message: message, is_error: true)
                }
              )
            end

            h.form_for(:user, on_submit: :handle_save, class: h.styles[:form]) do |f|
              h.div do
                h.h2(class: h.styles[:section_title]) { "Profile" }
              end

              h.div do
                f.label :username
                f.text_field :username, disabled: true, class: h.styles[:input_disabled]
              end

              h.div do
                f.label :display_name, "Display Name"
                f.text_field :display_name, class: h.styles[:input]
              end

              h.div do
                f.label :birthday, "Birthday"
                h.component(
                  Funicular::Plugins::DatePicker::Component,
                  name: "birthday",
                  value: state[:user][:birthday] || state[:user]["birthday"],
                  input_class: h.styles[:input],
                  on_change: ->(value) {
                    patch(user: state[:user].merge(birthday: value))
                  }
                )
              end

              f.submit(
                state[:saving] ? "Saving..." : "Save Changes",
                class: h.styles[:submit_button, state[:saving] ? :saving : :normal]
              )
            end
          end
        end
      end
    end
  end
end
