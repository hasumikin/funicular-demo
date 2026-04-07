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
    { message_input: "" }
  end

  def handle_input(event)
    patch(message_input: event.target[:value])
  end

  def handle_submit(event)
    event.preventDefault

    content = state.message_input.to_s.strip
    return if content.empty?

    form = event[:target]
    form.reset if form

    patch(message_input: "")

    props[:on_send_message].call(content)
  end

  def render
    div(class: s.input_area) do
      form(onsubmit: ->(event) { handle_submit(event) }, class: s.input_form) do
        input(
          ref: :message_input,
          type: "text",
          value: state.message_input,
          oninput: ->(event) { handle_input(event) },
          placeholder: "Type a message...",
          class: s.message_input
        )
        is_disabled = state.message_input.to_s.strip.empty?
        button(
          type: "submit",
          class: s.send_button(is_disabled ? :disabled : :enabled),
          disabled: is_disabled
        ) do
          span { "Send" }
        end
      end
    end
  end
end
