defmodule StridentWeb.Components.UploadImageForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.Aws
  alias Strident.Teams
  alias Strident.Tournaments

  @profile_picture_dimensions [h_view: 200, w_view: 200, h_upload: 200, w_upload: 200]
  @team_picture_dimensions [h_view: 200, w_view: 200, h_upload: 200, w_upload: 200]
  @tournament_cover_dimensions [h_view: 200, w_view: 776, h_upload: 500, w_upload: 1940]
  @tournament_thumbnail_dimensions [h_view: 200, w_view: 300, h_upload: 300, w_upload: 450]
  @profile_banner_dimensions [h_view: 200, w_view: 800, h_upload: 480, w_upload: 1920]

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign_aws_presign(assigns)
    |> assign_modalization(assigns)
    |> assign_inner_block(assigns)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "update_profile_picture",
        _params,
        %{assigns: %{upload_for: %Accounts.User{} = user, aws: aws, banner: true}} = socket
      ) do
    new_url = Aws.get_image_upload_url(aws.key)

    case Accounts.update_user(user, %{banner_url: new_url}) do
      {:ok, %{banner_url: banner_url}} ->
        update_avatar_url_in_parent(banner_url, :banner_url)
        track_segment_event(socket, "Banner Image Updated", %{banner_url: banner_url})
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not upload image.")}
    end
  end

  @impl true
  def handle_event(
        "update_profile_picture",
        _params,
        %{assigns: %{upload_for: %Accounts.User{} = user, aws: aws}} = socket
      ) do
    new_url = Aws.get_image_upload_url(aws.key)

    case Accounts.update_user(user, %{avatar_url: new_url}) do
      {:ok, %{avatar_url: avatar_url}} ->
        update_avatar_url_in_parent(avatar_url)
        track_segment_event(socket, "Avatar Image Updated", %{avatar_url: avatar_url})
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not upload image.")}
    end
  end

  @impl true
  def handle_event(
        "update_profile_picture",
        _params,
        %{assigns: %{upload_for: %Teams.Team{} = team, aws: aws, banner: true}} = socket
      ) do
    new_url = Aws.get_image_upload_url(aws.key)

    case Teams.update_team(team, %{banner_url: new_url}) do
      {:ok, %{banner_url: logo_url}} ->
        update_team_url_in_parent(logo_url, :banner_url)
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not upload image.")}
    end
  end

  @impl true
  def handle_event(
        "update_profile_picture",
        _params,
        %{assigns: %{upload_for: %Teams.Team{} = team, aws: aws}} = socket
      ) do
    new_url = Aws.get_image_upload_url(aws.key)

    case Teams.update_team(team, %{logo_url: new_url}) do
      {:ok, %{logo_url: logo_url}} ->
        update_team_url_in_parent(logo_url)
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not upload image.")}
    end
  end

  @impl true
  def handle_event(
        "update_profile_picture",
        _params,
        %{assigns: %{upload_for: %Tournaments.Tournament{} = tournament, aws: aws}} = socket
      ) do
    new_url = Aws.get_image_upload_url(aws.key)

    case Tournaments.update_tournament(tournament, %{cover_image_url: new_url}) do
      {:ok, %{cover_image_url: cover_image_url}} ->
        update_tournament_url_in_parent(cover_image_url, :cover_image_url)
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not upload image.")}
    end
  end

  @impl true
  def handle_event(
        "update_profile_picture",
        _params,
        %{assigns: %{upload_for: upload_for, aws: aws}} = socket
      ) do
    new_url = Aws.get_image_upload_url(aws.key)

    case upload_for do
      %{tournament_id: _, thumb: true} ->
        update_tournament_url_in_parent(new_url, :thumbnail_image_url)
        {:noreply, socket}

      %{tournament_id: _} ->
        update_tournament_url_in_parent(new_url, :cover_image_url)
        {:noreply, socket}

      %Ecto.Changeset{} = _changeset ->
        update_logo_url_in_parent(new_url)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("error_profile_picture", _params, socket) do
    {:noreply, put_flash(socket, :error, "Could not upload image.")}
  end

  defp assign_aws_presign(socket, %{
         upload_for: %Strident.Accounts.User{display_name: display_name} = upload_for
       }) do
    socket
    |> assign(@profile_picture_dimensions)
    |> assign(
      upload_for: upload_for,
      aws:
        Aws.presign_upload_url(
          Aws.get_user_key(display_name),
          "image/jpg"
        )
    )
  end

  defp assign_aws_presign(socket, %{upload_for: %Teams.Team{} = team, banner: true}) do
    socket
    |> assign(@profile_banner_dimensions)
    |> assign(
      upload_for: team,
      banner: true,
      aws:
        Aws.presign_upload_url(
          Aws.get_team_banner_key(team.slug),
          "image/jpg"
        )
    )
  end

  defp assign_aws_presign(socket, %{upload_for: %Teams.Team{} = team}) do
    socket
    |> assign(@team_picture_dimensions)
    |> assign(
      upload_for: team,
      aws:
        Aws.presign_upload_url(
          Aws.get_team_key(team.slug),
          "image/jpg"
        )
    )
  end

  defp assign_aws_presign(socket, %{
         upload_for: %{tournament_id: tournament_id, thumb: true} = upload_for
       }) do
    socket
    |> assign(@tournament_thumbnail_dimensions)
    |> assign(
      upload_for: upload_for,
      aws:
        Aws.presign_upload_url(
          Aws.get_tournament_thumbnail_key(tournament_id),
          "image/jpg"
        )
    )
  end

  defp assign_aws_presign(socket, %{upload_for: %{tournament_id: tournament_id} = upload_for}) do
    socket
    |> assign(@tournament_cover_dimensions)
    |> assign(
      upload_for: upload_for,
      aws:
        Aws.presign_upload_url(
          Aws.get_tournament_key(tournament_id),
          "image/jpg"
        )
    )
  end

  defp assign_aws_presign(socket, %{upload_for: %Ecto.Changeset{} = changeset}) do
    name = Slug.slugify(Ecto.Changeset.get_field(changeset, :name) || Ecto.UUID.generate())

    socket
    |> assign(@team_picture_dimensions)
    |> assign(
      upload_for: changeset,
      aws: Aws.presign_upload_url(Aws.get_team_key(name), "image/jpg")
    )
  end

  defp assign_aws_presign(socket, %{upload_for: %Tournaments.Tournament{} = tournament}) do
    socket
    |> assign(@tournament_cover_dimensions)
    |> assign(
      upload_for: tournament,
      aws: Aws.presign_upload_url(Aws.get_tournament_key(tournament.id), "image/jpg")
    )
  end

  defp assign_aws_presign(socket, %{banner: true}) do
    socket
    |> assign(@profile_banner_dimensions)
    |> assign(
      upload_for: socket.assigns.current_user,
      banner: true,
      aws:
        Aws.presign_upload_url(
          Aws.get_user_banner_key(socket.assigns.current_user.display_name),
          "image/jpg"
        )
    )
  end

  defp assign_aws_presign(socket, _assigns) do
    socket
    |> assign(@profile_picture_dimensions)
    |> assign(
      upload_for: socket.assigns.current_user,
      aws:
        Aws.presign_upload_url(
          Aws.get_user_key(socket.assigns.current_user.display_name),
          "image/jpg"
        )
    )
  end

  defp assign_modalization(socket, assigns) do
    socket
    |> assign(modalized: Map.get(assigns, :modalized, false))
    |> assign(modal_size: Map.get(assigns, :modal_size, "modal__dialog--medium"))
  end

  defp assign_inner_block(socket, assigns) do
    assign(socket, inner_block: Map.get(assigns, :inner_block))
  end

  defp update_avatar_url_in_parent(avatar_url, which_avatar \\ :avatar_url) do
    send(self(), {:current_user_updated, %{which_avatar => avatar_url}})
  end

  defp update_tournament_url_in_parent(avatar_url, which_avatar) do
    send(self(), {:tournament_updated, %{which_avatar => avatar_url}})
  end

  defp update_team_url_in_parent(logo_url, which_avatar \\ :logo_url) do
    send(self(), {:team_updated, %{which_avatar => logo_url}})
  end

  defp update_logo_url_in_parent(logo_url) do
    send(self(), {:team_updated, %{logo_url: logo_url}})
  end
end
