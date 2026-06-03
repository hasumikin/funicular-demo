class ChannelIndexComponent < Funicular::Component
  styles do
    container "min-h-screen bg-gray-50 py-10"
    inner "max-w-2xl mx-auto px-4"
    title "text-3xl font-bold text-gray-800 mb-6"
    lead "text-gray-600 mb-8"
    list "space-y-3"
    card "block bg-white rounded-lg shadow p-4 hover:shadow-md transition"
    name "text-lg font-semibold text-blue-700"
    desc "text-gray-600 text-sm mt-1"
    preview "text-gray-400 text-xs mt-2"
    empty "text-gray-500"
    nav "mb-6 text-sm"
    nav_link "text-blue-600 hover:underline"
  end

  def initialize_state
    { channels: [] }
  end

  def render
    div(class: s.container) do
      div(class: s.inner) do
        div(class: s.nav) do
          link_to "/blog", navigate: true, class: s.nav_link do
            span { "Read our blog" }
          end
        end
        h1(class: s.title) { "Explore Channels" }
        p(class: s.lead) do
          "This page is rendered on the server by Funicular and hydrated in the browser."
        end

        if state.channels.empty?
          p(class: s.empty) { "No channels yet." }
        else
          div(class: s.list) do
            state.channels.each do |ch|
              link_to "/chat/#{ch["id"]}", navigate: true, class: s.card, key: ch["id"] do
                div(class: s.name) { "# #{ch["name"]}" }
                div(class: s.desc) { ch["description"].to_s }
                if ch["latest_message"]
                  div(class: s.preview) { "latest: #{ch["latest_message"]}" }
                end
              end
            end
          end
        end
      end
    end
  end
end
