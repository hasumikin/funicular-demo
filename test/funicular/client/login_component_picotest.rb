class LoginComponentTest < Funicular::Testing::DOMTest
  def test_empty_submit_shows_validation_error
    mount LoginComponent
    submit "form"

    assert_text "Please enter username and password"
  end
end
