[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{heex,ex,exs}", "priv/*/seeds.exs", "{config,lib,test,seeds}/**/*.{heex,ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
