class Post < Funicular::Model
  # Attributes come from the server schema (load_schema).
  # Ephemeral: the blog is the SSR demo (state-passing, no local reads),
  # and the schema's "comments" array attribute has no replica column
  # representation.
  storage :ephemeral
end
