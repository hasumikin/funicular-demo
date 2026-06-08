require "test_helper"

class ChannelsControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get channels_url

    assert_response :unauthorized
    assert_equal "Unauthorized", response.parsed_body["error"]
  end

  test "returns channels for logged in user" do
    user = User.create!(username: "alice", password: "password")
    Channel.create!(name: "general", description: "General chat")
    Channel.create!(name: "random", description: "Off topic")

    post login_url, params: { username: user.username, password: "password" }
    assert_response :success

    get channels_url

    assert_response :success
    channels = response.parsed_body
    assert_equal ["general", "random"], channels.map { |channel| channel["name"] }
    assert_equal "General chat", channels.first["description"]
  end
end
