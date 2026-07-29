# Reproduces the first-visit chat flow end to end on the real render
# path: local database booted (volatile under Node), ChatComponent
# mounted into jsdom, Channel.all applying its rows through the real
# write-through, and the watch(:channels) delivery re-rendering the
# preserved ChannelListComponent.
class ChatComponentTest < Funicular::Testing::DOMTest
  CHANNEL_ROWS = [
    { "id" => 1, "name" => "general", "description" => "talk" },
    { "id" => 2, "name" => "random", "description" => "anything" },
  ].freeze

  class FakeSubscription
    def unsubscribe; end

    def perform(*_args); end
  end

  class FakeSubscriptions
    def create(_params, &_block)
      FakeSubscription.new
    end
  end

  class FakeConsumer
    def subscriptions
      FakeSubscriptions.new
    end
  end

  def setup
    super
    Funicular::DB.__reset_boot
    Funicular::DB.__set_local_database_enabled(true)
    Channel.load_schema(
      "attributes" => {
        "id" => { "type" => "integer", "readonly" => true },
        "name" => { "type" => "string", "readonly" => true },
        "description" => { "type" => "string", "readonly" => true }
      },
      "endpoints" => {}
    )
    User.load_schema(
      "attributes" => {
        "id" => { "type" => "integer", "readonly" => true },
        "username" => { "type" => "string", "readonly" => true },
        "display_name" => { "type" => "string", "readonly" => false },
        "has_avatar" => { "type" => "boolean", "readonly" => true }
      },
      "endpoints" => {}
    )
    Funicular::DB.boot(
      models: [Channel, Draft],
      metadata: { local_database: true,
                  application_id: "chat_component_test",
                  anonymous_only: true }
    )
    # The Session.current_user stub lives in settings_component_picotest.
    Session.__test_current_user = User.new(
      "id" => 1,
      "username" => "alice",
      "display_name" => "Alice",
      "has_avatar" => false
    )
    # A real router (never started: no route-driven mounting) supplies
    # the route helpers ChannelListComponent links with, and the global
    # Funicular.router select_channel consults.
    @router = Funicular::Router.new(container)
    @router.get('/chat', to: ChatComponent, as: 'chat')
    @router.get('/settings', to: SettingsComponent, as: 'settings')
    @router_before = Funicular.router
    Funicular.instance_variable_set(:@router, @router)
  end

  def teardown
    Funicular.instance_variable_set(:@router, @router_before)
    Session.__test_current_user = nil
    Funicular::DB.__reset_boot
    Funicular::DB.__set_local_database_enabled(false)
  end

  def mount_chat
    @component = ChatComponent.new({})
    @component.runtime = Funicular::Runtime.new(@router)
    @component.mount(container)
    drain
    @component
  end

  def test_first_visit_fetch_through_renders_the_channel_list
    mount_chat
    drain 100

    # The fetch-through wrote the replica; the watch delivery must have
    # re-rendered the (preserved) channel list.
    assert_equal 2, Channel.local.count
    assert_text "# general"
    assert_text "# random"
  end

  def test_a_remount_renders_instantly_from_the_replica
    mount_chat
    drain 100
    @component.unmount

    # Second visit (Settings and back): the initial watch
    # materialization alone must show the channels.
    mount_chat
    assert_text "# general"
  end
end

class Channel
  # Mirrors Model.all's contract: the whole collection reaches the
  # replica through the batch write-through BEFORE the callback runs.
  def self.all(&block)
    __write_through_upsert_all(ChatComponentTest::CHANNEL_ROWS)
    instances = []
    i = 0
    while i < ChatComponentTest::CHANNEL_ROWS.size
      instances << new(ChatComponentTest::CHANNEL_ROWS[i])
      i += 1
    end
    block.call(instances, nil)
  end
end

module Funicular
  module Cable
    def self.create_consumer(_url)
      ChatComponentTest::FakeConsumer.new
    end
  end
end
