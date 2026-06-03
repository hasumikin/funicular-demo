class HomeController < ApplicationController
  # Server-rendered public pages. Other paths fall through to plain
  # client-side rendering (empty #app) as before.
  def index
    case request.path
    when "/explore"
      @ssr = Funicular::SSR.render(path: "/explore", state: { channels: explore_channels })
    when "/blog"
      @ssr = Funicular::SSR.render(path: "/blog", state: { posts: blog_posts })
      @page_title = "Blog"
    when %r{\A/blog/(\d+)\z}
      render_blog_post(Regexp.last_match(1))
    end
  end

  private

  def render_blog_post(id)
    post = Post.find_by(id: id)
    return unless post

    @ssr = Funicular::SSR.render(
      path: "/blog/#{post.id}",
      state: {
        post: post_detail(post),
        comments: post_comments(post),
        current_user: current_user_hash
      }
    )
    @page_title = post.title
    @page_description = post.body.to_s.gsub(/\s+/, " ").strip[0, 160]
  end

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

  def blog_posts
    Post.published.map do |post|
      {
        "id" => post.id,
        "title" => post.title,
        "author_name" => post.author_name,
        "published_at" => post.published_at&.iso8601,
        "excerpt" => post.body.to_s.split("\n\n").first.to_s
      }
    end
  end

  def post_detail(post)
    {
      "id" => post.id,
      "title" => post.title,
      "body" => post.body,
      "author_name" => post.author_name,
      "published_at" => post.published_at&.iso8601
    }
  end

  def post_comments(post)
    post.comments.includes(:user).order(:created_at).map do |comment|
      {
        "id" => comment.id,
        "body" => comment.body,
        "author_name" => comment.user.display_name,
        "created_at" => comment.created_at.iso8601
      }
    end
  end

  # nil when anonymous; a small hash when logged in. The client trusts this on
  # hydration, so the server-rendered comment form matches the client.
  def current_user_hash
    return nil unless current_user
    { "id" => current_user.id, "display_name" => current_user.display_name }
  end
end
