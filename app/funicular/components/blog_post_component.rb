class BlogPostComponent < Funicular::Component
  styles do
    container "min-h-screen bg-gray-50 py-10"
    inner "max-w-2xl mx-auto px-4"
    back "mb-6 text-sm flex gap-4"
    back_link "text-blue-600 hover:underline"
    article_box "bg-white rounded-lg shadow p-6"
    title "text-3xl font-bold text-gray-800"
    meta "text-gray-400 text-sm mt-2 mb-6"
    body "text-gray-800 leading-relaxed whitespace-pre-line"
    comments_section "mt-10"
    comments_title "text-xl font-semibold text-gray-800 mb-4"
    comments_list "space-y-3"
    comment "bg-white rounded-lg shadow-sm p-4"
    comment_meta "text-gray-400 text-xs mb-1"
    comment_body "text-gray-700 text-sm"
    no_comments "text-gray-500 text-sm"
    form_box "mt-6 bg-white rounded-lg shadow p-4"
    form_title "text-sm font-semibold text-gray-700 mb-2"
    textarea "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
    submit "mt-2 px-5 py-2 rounded-md bg-blue-600 text-white font-semibold hover:bg-blue-700"
    submit_disabled "mt-2 px-5 py-2 rounded-md bg-blue-600 text-white font-semibold opacity-50 cursor-not-allowed"
    login_prompt "mt-6 text-sm text-gray-600"
    login_link "text-blue-600 hover:underline"
    missing "text-gray-500"
  end

  def initialize(params = {})
    super
    @post_id = params[:id]
  end

  def initialize_state
    { post: nil, comments: [], current_user: nil, comment: { body: "" }, errors: {}, interactive: false }
  end

  def component_mounted
    puts "BlogPostComponent mounted: comment form is ready"
    patch(interactive: true)

    # When the server injected the post (SSR + hydration) we trust its state,
    # including who the viewer is. Only fetch on pure client-side navigation.
    return unless state.post.nil?

    Post.find(@post_id) do |post, error|
      patch(post: post_to_h(post), comments: post.comments || []) unless error
    end
    Session.current_user do |user, error|
      patch(current_user: error ? nil : user_to_h(user))
    end
  end

  def handle_submit(event)
    event.preventDefault

    textarea = @refs[:comment_body]
    body = textarea ? textarea[:value].to_s.strip : state.comment[:body].to_s.strip
    return if body.empty?

    Comment.create({ post_id: state.post["id"], body: body }) do |comment, error|
      if error
        patch(errors: { body: error })
      else
        form = event[:target]
        form.reset if form
        textarea[:value] = "" if textarea

        patch(
          comments: state.comments + [comment_to_h(comment)],
          comment: { body: "" },
          errors: {}
        )
      end
    end
  end

  def render
    div(class: s.container) do
      div(class: s.inner) do
        div(class: s.back) do
          link_to "/blog", navigate: true, class: s.back_link do
            span { "All posts" }
          end
          link_to "/chat", navigate: true, class: s.back_link do
            span { "Back to chat" }
          end
        end

        if state.post.nil?
          p(class: s.missing) { "Loading post..." }
        else
          article(class: s.article_box) do
            h1(class: s.title) { state.post["title"] }
            div(class: s.meta) { "#{state.post["author_name"]} - #{format_date(state.post["published_at"])}" }
            div(class: s.body) { state.post["body"] }
          end

          section(class: s.comments_section) do
            h2(class: s.comments_title) { "Comments (#{state.comments.size})" }

            if state.comments.empty?
              p(class: s.no_comments) { "No comments yet." }
            else
              div(class: s.comments_list) do
                state.comments.each do |comment|
                  div(class: s.comment, key: comment["id"]) do
                    div(class: s.comment_meta) { "#{comment["author_name"]} - #{format_date(comment["created_at"])}" }
                    div(class: s.comment_body) { comment["body"] }
                  end
                end
              end
            end

            if state.current_user
              div(class: s.form_box) do
                div(class: s.form_title) { "Comment as #{state.current_user["display_name"]}" }
                if state.interactive
                  form(onsubmit: ->(event) { handle_submit(event) }, key: :comment_form_ready) do
                    textarea(
                      ref: :comment_body,
                      class: s.textarea,
                      rows: 3,
                      placeholder: "Share your thoughts..."
                    )
                    button(type: "submit", class: s.submit) do
                      span { "Post comment" }
                    end
                  end
                else
                  div(key: :comment_form_pending) do
                    textarea(
                      class: s.textarea,
                      rows: 3,
                      placeholder: "Share your thoughts...",
                      disabled: true
                    )
                    button(type: "button", class: s.submit_disabled, disabled: true) do
                      span { "Post comment" }
                    end
                  end
                end
              end
            else
              p(class: s.login_prompt) do
                link_to "/login", navigate: true, class: s.login_link do
                  span { "Log in to comment" }
                end
              end
            end
          end
        end
      end
    end
  end

  private

  # Convert Funicular::Model instances into the same string-keyed hash shapes
  # the server injects, so render reads them identically on both sides.
  def post_to_h(post)
    {
      "id" => post.id,
      "title" => post.title,
      "body" => post.body,
      "author_name" => post.author_name,
      "published_at" => post.published_at
    }
  end

  def comment_to_h(comment)
    {
      "id" => comment.id,
      "body" => comment.body,
      "author_name" => comment.author_name,
      "created_at" => comment.created_at
    }
  end

  def user_to_h(user)
    { "id" => user.id, "display_name" => user.display_name }
  end

  def format_date(iso)
    iso.to_s.split("T").first
  end
end
