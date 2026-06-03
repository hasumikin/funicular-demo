class CommentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :require_login

  def create
    post = Post.find(params[:post_id])
    comment = post.comments.build(body: params[:body], user: current_user)

    if comment.save
      render json: comment_json(comment), status: :created
    else
      render json: { error: comment.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  private

  def comment_json(comment)
    {
      id: comment.id,
      body: comment.body,
      author_name: comment.user.display_name,
      created_at: comment.created_at.iso8601
    }
  end
end
