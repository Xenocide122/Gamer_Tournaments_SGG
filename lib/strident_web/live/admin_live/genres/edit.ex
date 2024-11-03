defmodule StridentWeb.GenresLive.Edit do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Games

  def mount(%{"id" => id}, _session, socket) do
    genre = Games.get_genre!(id)

    socket
    |> assign(genre: genre)
    |> then(&{:ok, &1})
  end
end
