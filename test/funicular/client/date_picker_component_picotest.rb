class DatePickerComponentTest < Funicular::Testing::DOMTest
  def test_calendar_button_opens_panel
    mount Funicular::Plugins::DatePicker::Component, value: "2000-01-02"

    click ".funicular-date-picker__button"
    assert_selector ".funicular-date-picker__panel"
  end
end
