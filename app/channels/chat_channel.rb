class ChatChannel < ApplicationCable::Channel
  # TTL for idempotency keys (5 minutes)
  IDEMPOTENCY_TTL = 5.minutes

  def subscribed
    channel = Channel.find(params[:channel_id])
    stream_from "chat_#{channel.id}"

    messages = channel.messages.includes(:user).order(created_at: :desc).limit(100).reverse

    transmit({
      type: "initial_messages",
      messages: messages.map { |m|
        {
          id: m.id,
          content: m.content,
          created_at: m.created_at.iso8601,
          user: {
            id: m.user.id,
            username: m.user.username,
            display_name: m.user.display_name,
            has_avatar: m.user.avatar.present?
          }
        }
      }
    })
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def unsubscribed
    stop_all_streams
  end

  def send_message(data)
    # Check for duplicate message using idempotency key
    idempotency_key = data["_idempotency_key"]
    if idempotency_key.present? && duplicate_message?(idempotency_key)
      Rails.logger.info "[ChatChannel] Ignoring duplicate message: #{idempotency_key}"
      return
    end

    content = data["content"].to_s.strip
    if content.empty?
      transmit({ type: "error", message: "Message cannot be empty" })
      return
    end

    channel = Channel.find(params[:channel_id])
    message = channel.messages.create!(
      user: current_user,
      content: content
    )

    # Mark message as processed
    mark_message_processed(idempotency_key) if idempotency_key.present?

    ActionCable.server.broadcast "chat_#{channel.id}", {
      type: "new_message",
      message: {
        id: message.id,
        content: message.content,
        created_at: message.created_at.iso8601,
        user: {
          id: current_user.id,
          username: current_user.username,
          display_name: current_user.display_name,
          has_avatar: current_user.avatar.present?
        }
      }
    }
  rescue ActiveRecord::RecordInvalid => e
    transmit({ type: "error", message: e.message })
  end

  private

  def idempotency_cache_key(key)
    "chat_channel:idempotency:#{key}"
  end

  def duplicate_message?(idempotency_key)
    Rails.cache.exist?(idempotency_cache_key(idempotency_key))
  end

  def mark_message_processed(idempotency_key)
    Rails.cache.write(
      idempotency_cache_key(idempotency_key),
      true,
      expires_in: IDEMPOTENCY_TTL
    )
  end
end
