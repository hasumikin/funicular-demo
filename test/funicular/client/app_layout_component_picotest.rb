# Drives a real router through the layout block on the jsdom History
# API: the layout mounts once, each navigation under it swaps only the
# page at the outlet, and a route outside the block unmounts the frame.
class AppLayoutComponentTest < Funicular::Testing::DOMTest
  class ChatPage < Funicular::Component
    def render
      div { "chat page" }
    end
  end

  class SettingsPage < Funicular::Component
    def render
      div { "settings page" }
    end
  end

  class BlogPage < Funicular::Component
    def render
      div { "blog page" }
    end
  end

  def setup
    super
    User.load_schema(
      "attributes" => {
        "id" => { "type" => "integer", "readonly" => true },
        "username" => { "type" => "string", "readonly" => true },
        "display_name" => { "type" => "string", "readonly" => false },
        "has_avatar" => { "type" => "boolean", "readonly" => true }
      },
      "endpoints" => {}
    )
    # The Session.current_user stub lives in settings_component_picotest.
    Session.__test_current_user = User.new(
      "id" => 1,
      "username" => "alice",
      "display_name" => "Alice",
      "has_avatar" => false
    )
    @router = Funicular::Router.new(container)
    @router.layout(AppLayoutComponent) do
      @router.get('/chat', to: ChatPage, as: 'chat')
      @router.get('/settings', to: SettingsPage, as: 'settings')
    end
    @router.get('/blog', to: BlogPage, as: 'blog')
    @router_before = Funicular.router
    Funicular.instance_variable_set(:@router, @router)
  end

  def teardown
    @router.stop
    Funicular.instance_variable_set(:@router, @router_before)
    Session.__test_current_user = nil
  end

  def layout_root
    @router.instance_variable_get(:@layout_root)
  end

  def test_the_layout_frames_the_page_and_survives_navigation_under_it
    @router.navigate('/chat')
    drain

    assert_text "Funicular Chat"
    assert_text "@alice"
    assert_text "chat page"
    root = layout_root
    assert_equal true, root.mounted

    @router.navigate('/settings')
    drain

    assert_text "settings page"
    assert_no_text "chat page"
    # The layout must stay mounted between routes under it.
    assert root.equal?(layout_root)
    assert_equal [AppLayoutComponent], @router.current_layouts
  end

  def test_a_route_outside_the_layout_unmounts_the_frame
    @router.navigate('/chat')
    drain
    @router.navigate('/blog')
    drain

    assert_text "blog page"
    assert_no_text "Funicular Chat"
    assert_nil layout_root
    assert_equal [], @router.current_layouts
  end
end
