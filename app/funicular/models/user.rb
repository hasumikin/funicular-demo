class User < Funicular::Model
  # Most attributes and validations come from the server schema
  # (/api/schema/user, derived from the ActiveRecord model).
  #
  # Frontend-only validation can also be declared here; it merges with the
  # schema-derived rules. Patterns are JS RegExp (use ^...$, not \A...\z).
  validates :display_name, format: { with: /^[^@]+$/, message: "cannot contain @" }
end
