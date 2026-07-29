class Comment < Funicular::Model
  # Attributes come from the server schema (load_schema).
  # Ephemeral: comments ride inside Post payloads as an array attribute,
  # which cannot be mirrored into a replica table row by row.
  storage :ephemeral
end
