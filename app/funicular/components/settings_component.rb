class SettingsComponent < Funicular::Component
  styles do
    container "min-h-screen bg-gray-100 py-8"
    card "max-w-2xl mx-auto bg-white rounded-lg shadow-md p-8"
    header "flex items-center justify-between mb-6"
    title "text-2xl font-bold text-gray-800"
    back_button "text-blue-600 hover:text-blue-800"
    message base: "mb-4 p-4 border rounded",
            variants: {
              success: "bg-green-100 border-green-400 text-green-700",
              error: "bg-red-100 border-red-400 text-red-700"
            }
    form "space-y-6"
    section "space-y-3 pb-6 border-b border-gray-200"
    profile_section "space-y-6"
    label "block text-sm font-medium text-gray-700 mb-2"
    section_title "text-lg font-semibold text-gray-800"
    section_hint "text-sm text-gray-500"
    input "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
    file_input "w-full text-sm text-gray-700 cursor-pointer file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:bg-blue-600 file:text-white file:font-semibold file:cursor-pointer hover:file:bg-blue-700"
    input_disabled "w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-600"
    avatar_container "mb-2"
    avatar "w-24 h-24 rounded-full object-cover"
    loading_container "flex items-center justify-center py-8"
    loading_spinner "animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full"

    submit_button base: "w-full py-2 px-4 rounded-md transition duration-200 font-semibold",
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
    current_user = state[:current_user]

    current_user.display_name = display_name
    current_user.birthday = birthday
    # Funicular 0.5 REST callbacks are uniformly (result, error). On
    # success the server's row is already applied to the instance (and
    # the replica) before the callback runs -- no manual attribute
    # copying; keys absent from the response (has_avatar) are left
    # untouched.
    current_user.update do |updated, error|
      if updated
        patch(
          current_user: updated,
          saving: false,
          message: "Settings saved successfully!",
          is_error: false,
          user: {
            username: updated.username,
            display_name: updated.display_name,
            birthday: updated.birthday
          }
        )
      elsif error.respond_to?(:messages)
        # Client-side validation failed before any request: show inline,
        # per-field errors (rendered by form_for beside each field).
        patch(saving: false, errors: error.messages)
      else
        patch(saving: false, message: "Error: #{error}", is_error: true)
      end
    end
  end

  def render
    div(class: styles.container) do
      div(class: styles.card) do
        div(class: styles.header) do
          h1(class: styles.title) { "Settings" }
          button(
            onclick: -> { Funicular.router.navigate("/chat") },
            class: styles.back_button
          ) do
            span { "<- Back to Chat" }
          end
        end

        if state[:message]
          div(class: styles.message(state[:is_error] ? :error : :success)) do
            span { state[:message] }
          end
        end

        div do
          current_user = state[:current_user]

          if current_user.nil?
            div(class: styles.loading_container) do
              div(class: styles.loading_spinner)
            end
          else
            div(class: styles.section) do
              div do
                h2(class: styles.section_title) { "Avatar" }
                p(class: styles.section_hint) { "Image changes are saved immediately." }
              end
              component(
                Funicular::Plugins::ImageUploader::Component,
                src: current_user.has_avatar ? "/users/#{current_user.id}/avatar?t=#{state[:avatar_cache_buster]}" : nil,
                upload_url: "/users/#{current_user.id}/avatar",
                input_id: "avatar-input",
                file_field: "avatar",
                auto_upload: true,
                preview_container_class: styles.avatar_container,
                image_class: styles.avatar,
                input_class: styles.file_input,
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

            form_for(:user, on_submit: :handle_save, class: styles.form) do |f|
              div do
                h2(class: styles.section_title) { "Profile" }
              end

              div do
                f.label :username
                f.text_field :username, disabled: true, class: styles.input_disabled
              end

              div do
                f.label :display_name, "Display Name"
                f.text_field :display_name, class: styles.input
              end

              div do
                f.label :birthday, "Birthday"
                component(
                  Funicular::Plugins::DatePicker::Component,
                  name: "birthday",
                  value: state[:user][:birthday] || state[:user]["birthday"],
                  input_class: styles.input,
                  on_change: ->(value) {
                    patch(user: state[:user].merge(birthday: value))
                  }
                )
              end

              f.submit(
                state[:saving] ? "Saving..." : "Save Changes",
                class: styles.submit_button(state[:saving] ? :saving : :normal)
              )
            end
          end
        end
      end
    end
  end
end
