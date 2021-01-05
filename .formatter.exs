# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [create_view: 2, update_view: 2, replace_view: 2],
  export: [
    locals_without_parens: [create_view: 2, update_view: 2, replace_view: 2]
  ]
]
