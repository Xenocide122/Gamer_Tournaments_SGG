defmodule StridentWeb.TournamentLive.Create.TournamentType do
  @moduledoc """
  The "tournament type" form page, where user provides details.
  """
  use StridentWeb, :live_component

  @tournament_types [
    %{
      id: :invite_only,
      title: "Invite Only",
      description: "Your hand picked collection of participants invited by email",
      img_src: "/images/icon_awesome_envelope.svg"
    },
    %{
      id: :casting_call,
      title: "Open Registration",
      description:
        "Open this to anyone. We'll create a sign up page and give you a link to share",
      img_src: "/images/icon_awesome_users.svg"
    }
  ]

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{f: f, stages_structure: stages_structure} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:f, f)
    |> assign(:stages_structure, stages_structure)
    |> assign(:tournament_types, @tournament_types)
    |> then(&{:ok, &1})
  end
end
