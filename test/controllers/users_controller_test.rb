require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "updates birthday for current user" do
    user = User.create!(username: "alice", password: "password")

    post login_url, params: { username: user.username, password: "password" }
    patch user_url(user), params: { birthday: "1990-04-12" }

    assert_response :success
    assert_equal "1990-04-12", response.parsed_body["birthday"]
    assert_equal Date.new(1990, 4, 12), user.reload.birthday
  end

  test "schema exposes birthday as writable" do
    user = User.create!(username: "alice", password: "password")

    post login_url, params: { username: user.username, password: "password" }
    get api_schema_user_url

    assert_response :success
    birthday = response.parsed_body["attributes"]["birthday"]
    assert_equal "string", birthday["type"]
    assert_equal false, birthday["readonly"]
  end
end
