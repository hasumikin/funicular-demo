class LoginComponent < Funicular::Component
  styles do
    container "min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-500 to-purple-600"
    card "bg-white p-8 rounded-lg shadow-2xl w-96"
    title "text-3xl font-bold text-center mb-8 text-gray-800"
    error_box "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4"
    form "space-y-4"
    label "block text-sm font-medium text-gray-700 mb-2"
    input "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"

    button base: "w-full py-2 px-4 rounded-md transition duration-200 font-semibold",
           variants: {
             normal: "bg-blue-600 text-white hover:bg-blue-700",
             loading: "bg-blue-600 text-white hover:bg-blue-700 opacity-50 cursor-not-allowed"
           }

    hint "mt-6 text-center text-sm text-gray-600"
    hint_link "text-blue-600 hover:underline"
  end

  def initialize_state
    {
      user: { username: "", password: "" },
      errors: {},
      loading: false
    }
  end

  def component_mounted
    # A successful login rotates the session epoch, so the framework
    # reloads this page into the new user's namespace -- landing here
    # again. Forward signed-in visitors to the chat.
    Session.current_user do |user, error|
      Funicular.router.navigate("/chat") if user
    end
  end

  def handle_submit(data)
    if data[:username].to_s.empty? || data[:password].to_s.empty?
      patch(errors: { username: "Please enter username and password" })
      return
    end

    patch(loading: true, errors: {})

    # Login using Session model
    Session.login(data[:username], data[:password]) do |user, error|
      if user
        puts "Login successful: #{user.username}"
        Funicular.router.navigate("/chat")
      elsif Funicular::DB.session_terminated?
        # The login succeeded and rotated the session epoch: the
        # response was discarded and the framework is reloading the
        # page. Keep the loading state instead of flashing an error.
      else
        patch(loading: false, errors: { username: error })
      end
    end
  end

  def render
    div(class: styles.container) do
      div(class: styles.card) do
        h1(class: styles.title) { "Funicular Chat" }

        form_for(:user, on_submit: :handle_submit, class: styles.form) do |f|
          div do
            f.label :username
            f.text_field :username, class: styles.input, placeholder: "Enter your username", autofocus: true
          end

          div do
            f.label :password
            f.password_field :password, class: styles.input, placeholder: "Enter your password"
          end

          f.submit(
            state[:loading] ? "Logging in..." : "Login",
            class: styles.button(state[:loading] ? :loading : :normal)
          )
        end

        div(class: styles.hint) do
          span { "Demo use only - " }
          link_to "/blog", navigate: true, class: styles.hint_link do
            span { "read our blog" }
          end
        end
      end
    end
  end
end
