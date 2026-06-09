class SettingsComponentTest < Funicular::Testing::DOMTest
  def setup
    super
    User.load_schema(
      "attributes" => {
        "id" => { "type" => "integer", "readonly" => true },
        "username" => { "type" => "string", "readonly" => true },
        "display_name" => { "type" => "string", "readonly" => false },
        "birthday" => { "type" => "string", "readonly" => false },
        "has_avatar" => { "type" => "boolean", "readonly" => true }
      },
      "endpoints" => {
        "update" => { "method" => "PATCH", "path" => "/users/:id" }
      }
    )
    Session.__test_current_user = User.new(
      "id" => 1,
      "username" => "alice",
      "display_name" => "Alice",
      "birthday" => "2000-01-02",
      "has_avatar" => false
    )
  end

  def test_resolved_user_renders_settings_form
    Session.__test_current_user_called = false
    mount SettingsComponent
    drain 650

    assert_equal true, Session.__test_current_user_called
    states = @component.instance_variable_get("@suspense_states")
    assert_equal :resolved, states[:current_user]
    assert_text "Birthday"
    assert_text "Image changes are saved immediately."
    assert_selector "form"
    assert_selector "#avatar-input"
  end

  def test_calendar_button_opens_date_picker
    mount SettingsComponent
    drain 650

    click ".funicular-date-picker__button"
    assert_selector ".funicular-date-picker__panel"
  end
end

class Session
  class << self
    attr_accessor :__test_current_user
    attr_accessor :__test_current_user_called

    def current_user(&block)
      self.__test_current_user_called = true
      block.call(__test_current_user, nil)
    end
  end
end
