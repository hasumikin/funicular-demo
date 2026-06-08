require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "uses username as default display name" do
    user = User.new(username: "alice", password: "password")

    assert user.valid?
    assert_equal "alice", user.display_name
  end

  test "requires unique username" do
    User.create!(username: "alice", password: "password")

    duplicate = User.new(username: "alice", password: "password")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:username], "has already been taken"
  end
end
