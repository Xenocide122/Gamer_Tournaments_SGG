defmodule StridentWeb.Components.GenreFormComponent do
  @moduledoc """
  Form to allow for the editing of available genres
  """
  use StridentWeb, :live_component

  alias Strident.Games
  alias Strident.Games.Genre

  @impl true
  def update(%{genre: genre} = assigns, socket) do
    changeset = Games.change_genre(genre)

    socket
    |> assign(assigns)
    |> assign(:action, :edit)
    |> assign(:changeset, changeset)
    |> then(&{:ok, &1})
  end

  def update(assigns, socket) do
    changeset = Games.change_genre(%Genre{})

    socket
    |> assign(assigns)
    |> assign(:action, :new)
    |> assign(genre: nil)
    |> assign(:changeset, changeset)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("validate", %{"genre" => genre_params}, socket) do
    genre =
      if is_nil(socket.assigns.genre),
        do: %Genre{},
        else: socket.assigns.genre

    changeset =
      genre
      |> Games.change_genre(genre_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"genre" => genre_params}, socket) do
    save_genre(socket, genre_params)
  end

  defp save_genre(%{assigns: %{action: :edit}} = socket, genre_params) do
    case Games.update_genre(socket.assigns.genre, genre_params) do
      {:ok, _genre} ->
        {:noreply,
         socket
         |> put_flash(:info, "Genre updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_genre(%{assigns: %{action: :new}} = socket, genre_params) do
    case Games.create_genre(genre_params) do
      {:ok, _genre} ->
        {:noreply,
         socket
         |> put_flash(:info, "Genre created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
