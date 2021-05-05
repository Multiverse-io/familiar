# Used by "mix format"
locals_without_parens = [
  create_view: 2,
  update_view: 2,
  replace_view: 2,
  drop_view: 2,
  drop_view: 1,
  create_function: 2,
  update_function: 2,
  replace_function: 2,
  drop_function: 1,
  drop_function: 2
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
