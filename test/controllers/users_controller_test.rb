require "test_helper"
require "tempfile"

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

  test "updates avatar for current user" do
    user = User.create!(username: "alice", password: "password")

    post login_url, params: { username: user.username, password: "password" }

    Tempfile.create(["avatar", ".png"]) do |file|
      file.binmode
      file.write("\x89PNG\r\n\x1A\n")
      file.rewind

      patch avatar_user_url(user), params: {
        avatar: Rack::Test::UploadedFile.new(file.path, "image/png")
      }
    end

    assert_response :success
    assert_equal true, response.parsed_body["avatar_updated"]
    assert_equal avatar_user_path(user), response.parsed_body["image_url"]
    assert user.reload.avatar.present?
  end
end
