class Session < Funicular::Model
  # Ephemeral: the session schema has no id attribute, so its rows
  # cannot be mirrored into a replica table. Login/logout responses
  # rotate the session epoch server-side; the page reloads into the
  # new namespace automatically.
  storage :ephemeral

  def self.login(username, password, &block)
    create({ username: username, password: password }, model_class: User, &block)
  end

  def self.logout(&block)
    destroy(&block)
  end

  def self.current_user(&block)
    find(endpoint_name: "current", model_class: User) do |user, error|
      block.call(user, error) if block
    end
  end
end
