class UsersController < ApplicationController
  before_action :require_login
  skip_before_action :verify_authenticity_token, only: [:update_avatar]

  def show
    user = User.find(params[:id])
    render json: {
      id: user.id,
      username: user.username,
      display_name: user.display_name,
      birthday: user.birthday&.iso8601,
      has_avatar: user.avatar.present?
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def avatar
    user = User.find(params[:id])
    if user.avatar
      send_data user.avatar, type: 'image/png', disposition: 'inline'
    else
      head :not_found
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def update
    unless current_user.id == params[:id].to_i
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    if params[:display_name]
      current_user.display_name = params[:display_name]
    end

    if params.key?(:birthday)
      current_user.birthday = params[:birthday].presence
    end

    if current_user.save
      render json: {
        id: current_user.id,
        username: current_user.username,
        display_name: current_user.display_name,
        birthday: current_user.birthday&.iso8601
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_avatar
    unless current_user.id == params[:id].to_i
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    unless params[:avatar]
      return render json: { error: "Avatar file is required." }, status: :unprocessable_entity
    end

    validation_error = validate_avatar(params[:avatar])
    return render json: { error: validation_error }, status: :unprocessable_entity if validation_error

    current_user.avatar = params[:avatar].read

    if current_user.save
      render json: {
        avatar_updated: true,
        image_url: avatar_user_path(current_user)
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def validate_avatar(upload)
    allowed_types = %w[image/jpeg image/png image/gif image/webp]
    return "Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed." unless allowed_types.include?(upload.content_type)
    return "File too large. Maximum size is 5MB." if upload.size > 5.megabytes

    nil
  end
end
