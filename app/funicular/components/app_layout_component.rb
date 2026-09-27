# Shared frame for the signed-in screens (chat and settings): a top bar
# with the section links and the logout button, and the current page
# rendered at `outlet`.
#
# The routes under this layout are declared inside
# `router.layout(AppLayoutComponent) { ... }` in initializer.rb. The
# router keeps this component mounted while the user moves between
# those routes, so the bar never remounts and only the page below it
# changes. The router re-renders the layout on every navigation, which
# is how the active link follows the current path.
class AppLayoutComponent < Funicular::Component
  styles do
    frame "h-screen flex flex-col bg-gray-100"
    bar "flex items-center justify-between px-4 py-2 bg-gray-900 text-white"
    brand "text-lg font-bold"
    nav "flex items-center gap-4"
    nav_link base: "text-sm text-gray-300 hover:text-white",
             active: "text-white font-semibold underline"
    user_handle "text-sm text-gray-400"
    logout_button "text-sm text-red-400 hover:text-red-300 cursor-pointer"
    page "flex-1 min-h-0 overflow-y-auto"
  end

  def initialize_state
    { current_user: nil }
  end

  def component_mounted
    # One sign-in check for every screen under the layout. The pages
    # still resolve the user for their own data; this one only decides
    # whether the frame shows the user and the logout button.
    Session.current_user do |user, error|
      if error
        Funicular.router.navigate("/login")
      else
        patch(current_user: user)
      end
    end
  end

  def handle_logout(_event)
    # No draft cleanup needed: drafts live in the local database under
    # this user's namespace, invisible to the next account. The logout
    # response rotates the session epoch, so the framework reloads the
    # page into the anonymous namespace on its own.
    Session.logout do |_success, _error|
      Funicular.router.navigate("/login")
    end
  end

  def render
    current_path = Funicular.router.current_path.to_s

    div(class: styles.frame) do
      header(class: styles.bar) do
        span(class: styles.brand) { "Funicular Chat" }

        nav(class: styles.nav) do
          link_to routes.chat_path, navigate: true,
                  class: styles.nav_link(current_path.start_with?("/chat")) do
            span { "Chat" }
          end
          link_to routes.settings_path, navigate: true,
                  class: styles.nav_link(current_path == routes.settings_path) do
            span { "Settings" }
          end
          # The blog is outside the layout block: navigating there
          # unmounts this frame and mounts the blog page alone.
          link_to routes.blog_path, navigate: true, class: styles.nav_link(false) do
            span { "Blog" }
          end

          if state[:current_user]
            span(class: styles.user_handle) { "@#{state[:current_user].username}" }
            button(onclick: :handle_logout, class: styles.logout_button) do
              span { "Logout" }
            end
          end
        end
      end

      # The matched page (ChatComponent or SettingsComponent) renders here
      # with its route params as props.
      tag(:main, class: styles.page) { outlet }
    end
  end
end
