defmodule StridentWeb.PlayNowLive.InterestedPlayerForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Leads

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{current_user: current_user, interest_registered: interest_registered} = assigns,
        socket
      ) do
    is_pro_user = current_user && current_user.is_pro
    show_interested_player_form = !interest_registered && !is_pro_user
    show_interest_registered = interest_registered && !is_pro_user

    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      show_interested_player_form: show_interested_player_form,
      show_interest_registered: show_interest_registered
    })
    |> assign(:changeset, make_changeset())
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("validate", %{"interested_player" => params}, socket) do
    changeset =
      params
      |> Map.update!("game_profiles", &ensure_one_empty_string/1)
      |> Map.update!("social_profiles", &ensure_one_empty_string/1)
      |> Map.update!("favorite_games", &ensure_one_empty_string/1)
      |> make_changeset()
      |> Map.put(:action, :validate)

    socket
    |> assign(:changeset, changeset)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("create", %{"interested_player" => params}, socket) do
    case Leads.create_and_email_interested_player(params) do
      {:ok, _, _} ->
        socket
        |> track_segment_event("Play Now Form Submitted")
        |> push_event("interest_registered", %{interest_registered: true})
        |> put_flash(:info, "Thanks! We sent you an email.")
        |> assign(%{
          changeset: make_changeset(),
          show_interest_registered: true,
          show_interested_player_form: false
        })
        |> then(&{:noreply, &1})

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> put_flash(:error, "Please correct any errors and resubmit.")
        |> assign(:changeset, changeset)
        |> then(&{:noreply, &1})

      {:error, _} ->
        socket
        |> put_flash(:error, "Your email appears to be invalid.")
        |> then(&{:noreply, &1})
    end
  end

  defp make_changeset(attrs \\ %{}) do
    Leads.new_interested_player()
    |> Leads.change_interested_player(attrs)
  end

  defp ensure_one_empty_string(list) do
    if Enum.any?(list, &(&1 == "")), do: list, else: list ++ [""]
  end
end
