class BlogIndexComponent < Funicular::Component
  styles do
    container "min-h-screen bg-gray-50 py-10"
    inner "max-w-2xl mx-auto px-4"
    nav "mb-6 text-sm"
    nav_link "text-blue-600 hover:underline"
    title "text-3xl font-bold text-gray-800 mb-2"
    lead "text-gray-600 mb-8"
    list "space-y-4"
    card "block bg-white rounded-lg shadow p-5 hover:shadow-md transition"
    post_title "text-xl font-semibold text-blue-700"
    meta "text-gray-400 text-xs mt-1"
    excerpt "text-gray-600 text-sm mt-3"
    empty "text-gray-500"
  end

  def initialize_state
    { posts: [] }
  end

  def component_mounted
    # Client-side navigation fallback: if the server did not inject posts
    # (e.g. navigated here within the SPA), fetch them.
    return unless state.posts.empty?

    Post.all do |posts, error|
      patch(posts: posts.map { |post| post_to_h(post) }) unless error
    end
  end

  def render
    div(class: s.container) do
      div(class: s.inner) do
        div(class: s.nav) do
          link_to "/chat", navigate: true, class: s.nav_link do
            span { "Back to chat" }
          end
        end

        h1(class: s.title) { "Funicular Blog" }
        p(class: s.lead) do
          "Notes on building a chat app with Ruby on the front end. "\
          "Each post is rendered on the server and hydrated in the browser."
        end

        if state.posts.empty?
          p(class: s.empty) { "No posts yet." }
        else
          div(class: s.list) do
            state.posts.each do |post|
              link_to "/blog/#{post["id"]}", navigate: true, class: s.card, key: post["id"] do
                div(class: s.post_title) { post["title"] }
                div(class: s.meta) { "#{post["author_name"]} - #{format_date(post["published_at"])}" }
                div(class: s.excerpt) { post["excerpt"] }
              end
            end
          end
        end
      end
    end
  end

  private

  # Convert a Funicular::Model post into the same string-keyed hash shape the
  # server injects, so render reads it the same way on both sides.
  def post_to_h(post)
    {
      "id" => post.id,
      "title" => post.title,
      "author_name" => post.author_name,
      "published_at" => post.published_at,
      "excerpt" => post.excerpt
    }
  end

  def format_date(iso)
    iso.to_s.split("T").first
  end
end
