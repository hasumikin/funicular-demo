class SettingsComponent < Funicular::Component
  # Suspense: declare async data loading with on_resolve callback
  use_suspense :current_user,
    ->(resolve, reject) {
      Session.current_user do |user, error|
        if error
          Funicular.router.navigate("/login")
          reject.call(error)
        else
          resolve.call(user)
        end
      end
    },
    on_resolve: ->(user) {
      # Sync form state when user data is loaded (before re-render)
      patch(
        user: {
          username: user.username,
          display_name: user.display_name,
          birthday: user.birthday
        }
      )
    }

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
      avatar_cache_buster: Time.now.to_i
    }
  end

  def handle_save(data)
    patch(saving: true, message: nil, is_error: false, errors: {})
    save_with_model(data[:display_name], data[:birthday] || state.user[:birthday] || state.user["birthday"])
  end

  def save_with_model(display_name, birthday)
    # Preserve has_avatar state
    had_avatar = current_user.has_avatar

    current_user.display_name = display_name
    current_user.birthday = birthday
    current_user.update do |success, result|
      if success
        # Update suspense data directly
        current_user.instance_variable_set("@display_name", result["display_name"])
        current_user.instance_variable_set("@birthday", result["birthday"])
        # Preserve has_avatar if not included in response
        if result["has_avatar"].nil? && had_avatar
          current_user.instance_variable_set("@has_avatar", true)
        end

        patch(
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

  def render
    div(class: s.container) do
      div(class: s.card) do
        div(class: s.header) do
          h1(class: s.title) { "Settings" }
          button(
            onclick: -> { Funicular.router.navigate("/chat") },
            class: s.back_button
          ) do
            span { "<- Back to Chat" }
          end
        end

        if state.message
          div(class: s.message(state.is_error ? :error : :success)) do
            span { state.message }
          end
        end

        div do
          suspense(
            fallback: -> {
              div(class: s.loading_container) do
                div(class: s.loading_spinner)
              end
            },
            error: ->(e) {
              div(class: s.message(:error)) do
                span { "Failed to load user data" }
              end
            }
          ) do
            div(class: s.section) do
              div do
                h2(class: s.section_title) { "Avatar" }
                p(class: s.section_hint) { "Image changes are saved immediately." }
              end
              component(
                Funicular::Plugins::ImageUploader::Component,
                src: current_user.has_avatar ? "/users/#{current_user.id}/avatar?t=#{state.avatar_cache_buster}" : nil,
                upload_url: "/users/#{current_user.id}/avatar",
                input_id: "avatar-input",
                file_field: "avatar",
                auto_upload: true,
                preview_container_class: s.avatar_container,
                image_class: s.avatar,
                input_class: s.file_input,
                on_upload: ->(result) {
                  current_user.instance_variable_set("@has_avatar", true)
                  patch(
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

            form_for(:user, on_submit: :handle_save, class: s.form) do |f|
              div do
                h2(class: s.section_title) { "Profile" }
              end

              div do
                f.label :username
                f.text_field :username, disabled: true, class: s.input_disabled
              end

              div do
                f.label :display_name, "Display Name"
                f.text_field :display_name, class: s.input
              end

              div do
                f.label :birthday, "Birthday"
                component(
                  Funicular::Plugins::DatePicker::Component,
                  name: "birthday",
                  value: state.user[:birthday] || state.user["birthday"],
                  input_class: s.input,
                  on_change: ->(value) {
                    patch(user: state.user.merge(birthday: value))
                  }
                )
              end

              f.submit(
                state.saving ? "Saving..." : "Save Changes",
                class: s.submit_button(state.saving ? :saving : :normal)
              )
            end
          end
        end
      end
    end
  end
end
