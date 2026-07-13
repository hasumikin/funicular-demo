class BlogPostComponent < Funicular::Component
  styles do |css|
    css.define :container, "min-h-screen bg-gray-50 py-10"
    css.define :inner, "max-w-2xl mx-auto px-4"
    css.define :back, "mb-6 text-sm flex gap-4"
    css.define :back_link, "text-blue-600 hover:underline"
    css.define :article_box, "bg-white rounded-lg shadow p-6"
    css.define :title, "text-3xl font-bold text-gray-800"
    css.define :meta, "text-gray-400 text-sm mt-2 mb-6"
    css.define :body, "text-gray-800 leading-relaxed whitespace-pre-line"
    css.define :comments_section, "mt-10"
    css.define :comments_title, "text-xl font-semibold text-gray-800 mb-4"
    css.define :comments_list, "space-y-3"
    css.define :comment, "bg-white rounded-lg shadow-sm p-4"
    css.define :comment_meta, "text-gray-400 text-xs mb-1"
    css.define :comment_body, "text-gray-700 text-sm"
    css.define :no_comments, "text-gray-500 text-sm"
    css.define :form_box, "mt-6 bg-white rounded-lg shadow p-4"
    css.define :form_title, "text-sm font-semibold text-gray-700 mb-2"
    css.define :textarea, "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
    css.define :submit, "mt-2 px-5 py-2 rounded-md bg-blue-600 text-white font-semibold hover:bg-blue-700"
    css.define :submit_disabled, "mt-2 px-5 py-2 rounded-md bg-blue-600 text-white font-semibold opacity-50 cursor-not-allowed"
    css.define :login_prompt, "mt-6 text-sm text-gray-600"
    css.define :login_link, "text-blue-600 hover:underline"
    css.define :missing, "text-gray-500"
  end

  def initialize(params = {})
    super
    @post_id = params[:id]
  end

  def initialize_state
    { post: nil, comments: [], current_user: nil, comment: { body: "" }, errors: {}, interactive: false, submitting: false }
  end

  def component_mounted
    puts "BlogPostComponent mounted: comment form is ready"
    patch(interactive: true)

    # When the server injected the post (SSR + hydration) we trust its state,
    # including who the viewer is. Only fetch on pure client-side navigation.
    return unless state[:post].nil?

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
    body = textarea ? textarea[:value].to_s.strip : state[:comment][:body].to_s.strip
    return if body.empty?

    patch(submitting: true, errors: {})

    Comment.create({ post_id: state[:post]["id"], body: body }) do |comment, error|
      if error
        patch(errors: { body: error }, submitting: false)
      else
        form = event[:target]
        form.reset if form
        textarea[:value] = "" if textarea

        reload_post_comments
      end
    end
  end

  def reload_post_comments
    Post.find(state[:post]["id"]) do |post, error|
      if error
        patch(errors: { body: error }, submitting: false)
      else
        patch(
          post: post_to_h(post),
          comments: post.comments || [],
          comment: { body: "" },
          errors: {},
          submitting: false
        )
      end
    end
  end

  def render(h)
    h.div(class: h.styles[:container]) do
      h.div(class: h.styles[:inner]) do
        h.div(class: h.styles[:back]) do
          h.link_to "/blog", navigate: true, class: h.styles[:back_link] do
            h.span { "All posts" }
          end
          h.link_to "/chat", navigate: true, class: h.styles[:back_link] do
            h.span { "Back to chat" }
          end
        end

        if state[:post].nil?
          h.p(class: h.styles[:missing]) { "Loading post..." }
        else
          h.article(class: h.styles[:article_box]) do
            h.h1(class: h.styles[:title]) { state[:post]["title"] }
            h.div(class: h.styles[:meta]) { "#{state[:post]["author_name"]} - #{format_date(state[:post]["published_at"])}" }
            h.div(class: h.styles[:body]) { state[:post]["body"] }
          end

          h.section(class: h.styles[:comments_section]) do
            h.h2(class: h.styles[:comments_title]) { "Comments (#{state[:comments].size})" }

            if state[:comments].empty?
              h.p(class: h.styles[:no_comments]) { "No comments yet." }
            else
              h.div(class: h.styles[:comments_list]) do
                state[:comments].each do |comment|
                  h.div(class: h.styles[:comment], key: comment["id"]) do
                    h.div(class: h.styles[:comment_meta]) { "#{comment["author_name"]} - #{format_date(comment["created_at"])}" }
                    h.div(class: h.styles[:comment_body]) { comment["body"] }
                  end
                end
              end
            end

            if state[:current_user]
              h.div(class: h.styles[:form_box]) do
                h.div(class: h.styles[:form_title]) { "Comment as #{state[:current_user]["display_name"]}" }
                if state[:interactive]
                  h.form(onsubmit: ->(event) { handle_submit(event) }, key: :comment_form_ready) do
                    h.textarea(
                      ref: :comment_body,
                      class: h.styles[:textarea],
                      rows: 3,
                      placeholder: "Share your thoughts...",
                      disabled: state[:submitting]
                    )
                    h.button(
                      type: "submit",
                      class: state[:submitting] ? h.styles[:submit_disabled] : h.styles[:submit],
                      disabled: state[:submitting]
                    ) do
                      h.span { state[:submitting] ? "Posting..." : "Post comment" }
                    end
                  end
                else
                  h.div(key: :comment_form_pending) do
                    h.textarea(
                      class: h.styles[:textarea],
                      rows: 3,
                      placeholder: "Share your thoughts...",
                      disabled: true
                    )
                    h.button(type: "button", class: h.styles[:submit_disabled], disabled: true) do
                      h.span { "Post comment" }
                    end
                  end
                end
              end
            else
              h.p(class: h.styles[:login_prompt]) do
                h.link_to "/login", navigate: true, class: h.styles[:login_link] do
                  h.span { "Log in to comment" }
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
