class HomeController < ApplicationController
  # Public, server-rendered channel directory. Other paths fall through to
  # plain client-side rendering (empty #app) as before.
  def index
    if request.path == "/explore"
      @ssr = Funicular::SSR.render(path: "/explore", state: { channels: explore_channels })
    end
  end

  private

  def explore_channels
    Channel.order(:name).map do |channel|
      latest = channel.messages.order(created_at: :desc).first
      {
        "id" => channel.id,
        "name" => channel.name,
        "description" => channel.description,
        "latest_message" => latest&.content
      }
    end
  end
end
