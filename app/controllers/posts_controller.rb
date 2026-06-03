class PostsController < ApplicationController
  # Public: the blog is readable without logging in.

  def index
    render json: Post.published.map { |post| post_summary(post) }
  end

  def show
    post = Post.find(params[:id])
    render json: post_detail(post)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  private

  def post_summary(post)
    {
      id: post.id,
      title: post.title,
      author_name: post.author_name,
      published_at: post.published_at&.iso8601,
      excerpt: post.body.to_s.split("\n\n").first.to_s
    }
  end

  def post_detail(post)
    {
      id: post.id,
      title: post.title,
      body: post.body,
      author_name: post.author_name,
      published_at: post.published_at&.iso8601,
      comments: post.comments.includes(:user).order(:created_at).map { |c| comment_json(c) }
    }
  end

  def comment_json(comment)
    {
      id: comment.id,
      body: comment.body,
      author_name: comment.user.display_name,
      created_at: comment.created_at.iso8601
    }
  end
end
