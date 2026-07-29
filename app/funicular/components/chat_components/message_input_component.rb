class MessageInputComponent < Funicular::Component
  styles do
    input_area "bg-white border-t border-gray-200 p-4"
    input_form "flex space-x-2"
    message_input "flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
    send_button base: "px-6 py-2 rounded-lg font-semibold transition-opacity",
                variants: {
                  enabled: "bg-blue-600 text-white hover:bg-blue-700",
                  disabled: "bg-blue-600 text-white opacity-50 cursor-not-allowed"
                }
  end

  def initialize_state
    { message_input: "", current_channel_id: nil }
  end

  def component_mounted
    patch(current_channel_id: props[:channel_id])
    restore_draft
  end

  def component_updated
    new_channel_id = props[:channel_id]
    old_channel_id = state[:current_channel_id]
    return if new_channel_id == old_channel_id

    # Channel changed: save the old channel's draft, load the new one.
    save_draft(old_channel_id, state[:message_input])
    patch(current_channel_id: new_channel_id, message_input: "")
    restore_draft
  end

  def handle_input(event)
    text = event.target[:value]
    patch(message_input: text)
    # Synchronous local-database write per keystroke; the framework
    # debounces the IndexedDB snapshot on its own, so no hand-rolled
    # save timer is needed anymore.
    save_draft(props[:channel_id], text)
  end

  def handle_submit(event)
    event.preventDefault

    content = state[:message_input].to_s.strip
    return if content.empty?

    form = event[:target]
    form.reset if form

    patch(message_input: "")
    discard_draft(props[:channel_id])

    props[:on_send_message].call(content)
  end

  def render
    div(class: styles.input_area) do
      form(onsubmit: ->(event) { handle_submit(event) }, class: styles.input_form) do
        input(
          ref: :message_input,
          type: "text",
          value: state[:message_input],
          oninput: ->(event) { handle_input(event) },
          placeholder: "Type a message...",
          class: styles.message_input
        )
        is_disabled = state[:message_input].to_s.strip.empty?
        button(
          type: "submit",
          class: styles.send_button(is_disabled ? :disabled : :enabled),
          disabled: is_disabled
        ) do
          span { "Send" }
        end
      end
    end
  end

  private

  def restore_draft
    draft = Draft.for_channel(props[:channel_id])
    patch(message_input: draft.body) if draft && !draft.body.to_s.empty?
  end

  # A reader tab (another tab holds the writer lock) cannot write to
  # the local database: drafts simply do not save there.
  def save_draft(channel_id, text)
    Draft.store(channel_id, text)
  rescue Funicular::DB::ReadOnlyTabError
    nil
  end

  def discard_draft(channel_id)
    Draft.discard(channel_id)
  rescue Funicular::DB::ReadOnlyTabError
    nil
  end
end
