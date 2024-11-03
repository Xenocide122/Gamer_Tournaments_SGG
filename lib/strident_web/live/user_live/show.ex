defmodule StridentWeb.UserLive.Show do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.Games
  alias Strident.Placements
  alias Strident.SocialMedia
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.SocialMedia.SocialMediaLinkUser
  alias Strident.Teams
  alias Strident.Tournaments
  alias Strident.UrlGeneration
  alias Strident.UserTournamentResults
  alias StridentWeb.Components.PhotoGallery
  alias StridentWeb.Router.Helpers, as: Routes
  alias StridentWeb.UserLive.StreamAndVods
  alias Phoenix.LiveView.JS

  @show_tournament_page_link Application.compile_env(:strident, :env) in [:dev, :test] or
                               !is_nil(System.get_env("IS_STAGING"))

  @page_size 8
  @status_filters %{
    "All" => %{
      status: [
        :scheduled,
        :registrations_open,
        :registrations_closed,
        :in_progress,
        :under_review,
        :finished
      ]
    },
    "Live and Upcoming" => %{
      status: [:scheduled, :registrations_open, :registrations_closed, :in_progress],
      sort: %{sort_order: :asc}
    },
    "Past Tournaments" => %{status: [:under_review, :finished], sort: %{sort_order: :desc}}
  }
  @staff_only_status_filters %{"Cancelled" => %{status: [:cancelled], sort: %{sort_order: :desc}}}
  @tournament_preloads [:game, :participants]

  on_mount(__MODULE__)

  def on_mount(:default, %{"slug" => "redacted"}, _session, socket) do
    socket
    |> put_flash(:error, "Could not find user")
    |> redirect(to: "/")
    |> then(&{:halt, &1})
  end

  def on_mount(:default, %{"slug" => slug} = params, _session, socket) do
    case Accounts.get_user_with_preloads_by([slug: slug], [
           :favorite_games,
           :teams,
           :featured_team,
           :social_media_links,
           :photos,
           :discord_connections
         ]) do
      nil ->
        socket
        |> put_flash(:error, "Could not find user #{inspect(slug)}")
        |> redirect(to: "/")
        |> then(&{:halt, &1})

      user ->
        type =
          case params do
            %{"type" => "following"} -> :following
            %{"type" => "followers"} -> :followers
            _ -> :statistic
          end

        status_filters =
          case socket.assigns.current_user do
            %{is_staff: true} -> Map.merge(@status_filters, @staff_only_status_filters)
            _ -> @status_filters
          end

        user = set_social_media_virtual_fields(user)

        socket
        |> assign(:user, user)
        |> assign(:status_filters, Map.keys(status_filters))
        |> assign(:games, Games.list_games())
        |> assign(:page_title, "#{user.display_name}'s Profile")
        |> assign(:page_image, Strident.Accounts.avatar_url(user))
        |> assign(
          :page_description,
          user.bio || "Join #{user.display_name} on Stride. Make sure you follow them!"
        )
        |> assign(:show, type)
        |> assign(:edit_details, false)
        |> assign(:edit_bio, false)
        |> assign(:edit_recent_results, false)
        |> assign(:changeset, Accounts.change_user_details(user))
        |> assign(:bio_changeset, Accounts.change_user_bio(user))
        |> assign(:form, to_form(%{}, as: :filter_status_form))
        |> assign_current_user_follows_user?()
        |> assign_user_stake_statistic()
        |> assign_followers_and_following()
        |> assign_following_open_to()
        |> assign_followers_open_to()
        |> assign_player_teammates()
        |> assign_tournaments()
        |> assign_recent_results()
        |> assign_page_share_link()
        |> assign(show_tournament_page_link: @show_tournament_page_link)
        |> then(&{:cont, &1})
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("open-followers", _params, %{assigns: %{followers_open_to: open_to}} = socket) do
    socket =
      socket
      |> assign(:show, :followers)
      |> push_patch(to: open_to)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open-following", _params, %{assigns: %{following_open_to: open_to}} = socket) do
    socket =
      socket
      |> assign(:show, :following)
      |> push_patch(to: open_to)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open-statistic", _params, socket) do
    {:noreply, assign(socket, :show, :statistic)}
  end

  @impl true
  def handle_event("follow", _value, %{assigns: %{user: user}} = socket) do
    {:noreply, follow_action(socket, user)}
  end

  def handle_event("unfollow", _value, %{assigns: %{user: user}} = socket) do
    {:noreply, unfollow_action(socket, user)}
  end

  def handle_event(
        "filter-status",
        %{"filter_status_form" => %{"filter" => filter_by_status}},
        socket
      ) do
    socket
    |> assign(filtered_status: filter_by_status)
    |> apply_filters()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("load-more", _, %{assigns: %{number_loaded: number_loaded}} = socket) do
    socket
    |> assign(number_loaded: number_loaded + @page_size)
    |> apply_filters()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "game-clicked",
        %{"game_id" => game_id},
        %{assigns: %{user: %{id: user_id} = user, current_user: %{id: user_id}}} = socket
      ) do
    socket =
      case Games.toggle_user_favorite_game(user.id, game_id) do
        {:created, game} ->
          socket
          |> track_segment_event("Favorite Game Added", %{title: game.title})
          |> assign(:user, %{user | favorite_games: [game | user.favorite_games]})

        {:deleted, game} ->
          socket
          |> track_segment_event("Favorite Game Removed", %{title: game.title})
          |> assign(:user, %{user | favorite_games: List.delete(user.favorite_games, game)})

        {:error, changeset} ->
          put_humanized_changeset_errors_in_flash(socket, changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "toggle-edit-details",
        _params,
        %{assigns: %{edit_details: edit_details, user: user}} = socket
      ) do
    {:noreply,
     assign(socket,
       edit_details: not edit_details,
       changeset: Accounts.change_user_details(user)
     )}
  end

  @impl true
  def handle_event(
        "update-user-details",
        %{"user" => params},
        %{assigns: %{user: %{id: user_id} = user, current_user: %{id: user_id}}} = socket
      ) do
    params =
      Map.update(
        params,
        "social_media_link_user",
        %{},
        &build_social_media_changes(Map.to_list(&1), user.social_media_link_user)
      )

    case Accounts.update_user_details(user, params) do
      {:ok, %{social_media_updates: updated_links, user_details_update: updated_details}} ->
        updated_user =
          updated_details
          |> Map.put(:social_media_link_user, updated_links)
          |> Map.put(:social_media_links, Enum.map(updated_links, & &1.social_media_link))

        socket
        |> assign(edit_details: false, user: updated_user)
        |> then(&{:noreply, &1})

      {:ok, %{user_details_update: updated_details}} ->
        updated_user =
          updated_details
          |> Map.put(:social_media_link_user, user.social_media_link_user)
          |> Map.put(:social_media_links, user.social_media_links)

        socket
        |> assign(edit_details: false, user: updated_user)
        |> then(&{:noreply, &1})

      {:error, _, error, _} ->
        socket
        |> put_string_or_changeset_error_in_flash(error)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("add-new-social-media", _params, %{assigns: %{changeset: changeset}} = socket) do
    {:noreply, assign(socket, changeset: add_new_social_media_link_user(changeset))}
  end

  @impl true
  def handle_event(
        "remove-social-media",
        %{"index" => index},
        %{assigns: %{changeset: changeset, user: user}} = socket
      ) do
    index = String.to_integer(index)

    changeset =
      if index < length(user.social_media_link_user) do
        set_delete_social_media_link_user(changeset, index)
      else
        remove_social_media_link_user(changeset, index)
      end

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "validate-social-media",
        %{"user" => params},
        %{assigns: %{user: user}} = socket
      ) do
    params =
      Map.update(
        params,
        "social_media_link_user",
        %{},
        &build_social_media_changes(Map.to_list(&1), user.social_media_link_user)
      )

    changeset = Accounts.change_user_details(user, params)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("toggle-edit-bio", _, %{assigns: %{edit_bio: edit_bio, user: user}} = socket) do
    {:noreply,
     assign(socket, edit_bio: not edit_bio, bio_changeset: Accounts.change_user_bio(user))}
  end

  @impl true
  def handle_event(
        "update-user-bio",
        %{"user" => params},
        %{assigns: %{user: %{id: user_id} = user, current_user: %{id: user_id}}} = socket
      ) do
    case Accounts.update_user_bio(user, params) do
      {:ok, updated_user} ->
        socket
        |> assign(user: updated_user, edit_bio: false)
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        socket
        |> assign(bio_changeset: changeset)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event(
        "toggle-edit-recent-results",
        _,
        %{assigns: %{edit_recent_results: edit_recent_results, user: user}} = socket
      ) do
    {:noreply,
     assign(socket,
       edit_recent_results: not edit_recent_results,
       profile_importer_changeset: Accounts.change_user_imported_profiles(user)
     )}
  end

  @impl true
  def handle_event(
        "validate-user-recent-results",
        %{"user" => params},
        %{assigns: %{user: user}} = socket
      ) do
    {:noreply,
     assign(socket,
       profile_importer_changeset: Accounts.change_user_imported_profiles(user, params)
     )}
  end

  @impl true
  def handle_event(
        "update-user-recent-results",
        %{"user" => params},
        %{assigns: %{user: %{id: user_id} = user, current_user: %{id: user_id}}} = socket
      ) do
    case Accounts.update_user_imported_profiles(user, params) do
      {:ok, updated_user} ->
        socket
        |> assign(
          recent_placements:
            Placements.get_user_recent_external_placements(user, pagination: %{limit: 4}),
          edit_recent_results: false,
          user: updated_user
        )
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "Could not update user details")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event(
        "impersonate",
        _params,
        %{assigns: %{current_user: %User{} = current_user, user: %User{is_staff: false} = user}} =
          socket
      ) do
    case Accounts.get_user_with_preloads_by(id: current_user.id) do
      %User{is_staff: true} ->
        socket
        |> push_navigate(to: Routes.impersonate_user_path(socket, :impersonate, user_id: user.id))
        |> then(&{:noreply, &1})

      _ ->
        {:noreply, put_flash(socket, :error, "You don't have permission for this action")}
    end
  end

  def handle_event("impersonate", _params, socket) do
    {:noreply, put_flash(socket, :error, "Cannot impersonate this user")}
  end

  @impl true
  def handle_info({:current_user_updated, attrs}, socket) do
    socket
    |> update(
      :current_user,
      &Map.merge(&1, attrs)
    )
    |> update(
      :user,
      &Map.merge(&1, attrs)
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(
        {:ssl, {:sslsocket, {:gen_tcp, port, :tls_connection, :undefined}, pids}, _some_binary},
        socket
      ) do
    Logger.warning("unusual info message in UserLive Show. port: #{inspect(port)}")

    for pid <- pids do
      Logger.warning(
        "unusual info message in UserLive Show with pid #{inspect(pid)}: #{inspect(Process.info(pid))}"
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(event, socket) do
    Logger.error("Got unhandled event in #{__MODULE__}.handle_info/2, #{inspect(event)}")
    {:noreply, socket}
  end

  def assign_user_stake_statistic(socket) do
    assign(socket, :statistic, %{})
  end

  def assign_current_user_follows_user?(
        %{assigns: %{user: user, current_user: current_user}} = socket
      ) do
    assign(socket, :following_user, follows?(current_user, user))
  end

  defp assign_page_share_link(socket) do
    %{assigns: %{user: user}} = socket

    StridentWeb.Endpoint
    |> Routes.user_show_path(:show, user.slug)
    |> UrlGeneration.absolute_path()
    |> then(&assign(socket, :page_share_link, &1))
  end

  defp follows?(nil, _user), do: false

  defp follows?(current_user, %Accounts.User{} = user) do
    Accounts.user_follows_user?(current_user, user)
  end

  @doc """
  Function that assigns followers and following for the user, also checks if current user is following
  followers or followings of the user.
  """
  def assign_followers_and_following(
        %{assigns: %{user: user, current_user: current_user}} = socket
      ) do
    followers = Accounts.get_user_followers(user.id, current_user && current_user.id)

    following =
      [
        Accounts.get_user_following(user.id, current_user && current_user.id),
        Accounts.get_user_following_teams(user.id, current_user && current_user.id)
      ]
      |> Enum.concat()
      |> Enum.sort_by(& &1.id)

    socket
    |> assign(:followers, followers)
    |> assign(:following, following)
  end

  def assign_followers_open_to(%{assigns: %{user: %User{} = user}} = socket) do
    assign(socket, :followers_open_to, Routes.user_followers_path(socket, :show, user.slug))
  end

  def assign_following_open_to(%{assigns: %{user: %User{} = user}} = socket) do
    assign(socket, :following_open_to, Routes.user_following_path(socket, :show, user.slug))
  end

  def assign_tournaments(%{assigns: %{user: user}} = socket) do
    socket =
      assign(socket,
        filtered_status: "All",
        number_loaded: @page_size,
        upcoming_tournaments:
          Tournaments.get_tournaments_with_filters(
            [
              with_creator_or_participant: user.id,
              status: [
                :scheduled,
                :registrations_open,
                :registrations_closed,
                :in_progress,
                :under_review,
                :finished
              ],
              limit: 4,
              filter_by_scrims_or_tournaments: false,
              sort: %{sort_by: :starts_at, sort_order: :asc}
            ],
            @tournament_preloads
          )
      )
      |> apply_filters()

    assign(socket, has_tournaments: socket.assigns.tournaments.total_entries > 0)
  end

  defp assign_player_teammates(%{assigns: %{user: user}} = socket) do
    assign(socket, teammates: Teams.get_user_teammates(user))
  end

  defp assign_recent_results(%{assigns: %{user: user}} = socket) do
    assign(socket,
      recent_results:
        UserTournamentResults.user_tournament_results(user, pagination: %{limit: 4}),
      recent_placements:
        Placements.get_user_recent_external_placements(user, pagination: %{limit: 4})
    )
  end

  defp is_my_profile?(%{id: user_id}, %{id: user_id}), do: true
  defp is_my_profile?(_, _), do: false

  defp apply_filters(%{assigns: assigns} = socket) do
    @status_filters
    |> Map.merge(@staff_only_status_filters)
    |> Map.get(assigns.filtered_status, %{})
    |> Map.merge(%{
      with_creator_or_participant: assigns.user.id,
      limit: assigns.number_loaded,
      filter_by_scrims_or_tournaments: false
    })
    |> Keyword.new()
    |> then(
      &assign(
        socket,
        :tournaments,
        Tournaments.get_tournaments_with_filters(&1, @tournament_preloads)
      )
    )
  end

  defp follow_action(%{assigns: %{current_user: %{id: current_user_id}}} = socket, user) do
    case Accounts.follow_user(user.id, current_user_id) do
      {:ok, _user_follower} ->
        socket
        |> assign(:following_user, true)
        |> tap(fn _ -> Segment.Analytics.track(current_user_id, "User Followed") end)

      _ ->
        put_flash(socket, :error, "Cannot follow user")
    end
  end

  defp follow_action(socket, _user) do
    put_flash(socket, :error, "Please log in to follow this user.")
  end

  defp unfollow_action(%{assigns: %{current_user: %{id: current_user_id}}} = socket, user) do
    case Accounts.unfollow_user(user.id, current_user_id) do
      {:ok, _user_follower} -> assign(socket, :following_user, false)
      _ -> put_flash(socket, :error, "Could not follow this user.")
    end
  end

  defp unfollow_action(socket, _user) do
    put_flash(socket, :error, "Please log in to unfollow this user.")
  end

  defp my_teams(%{teams: teams}) do
    Enum.map(teams, &{&1.name, &1.id})
  end

  defp set_social_media_virtual_fields(user) do
    Map.update(
      user,
      :social_media_link_user,
      [],
      &Enum.map(&1, fn %{social_media_link: sml} = smlu ->
        input = SocialMedia.url(sml.brand, sml.handle)

        %{
          smlu
          | social_media_link: Map.merge(sml, %{user_input: input, delete: false})
        }
      end)
    )
  end

  defp add_new_social_media_link_user(changeset) do
    social_media =
      [
        build_social_media()
        | Changeset.get_change(
            changeset,
            :social_media_link_user,
            Changeset.get_field(changeset, :social_media_link_user, [])
          )
      ]
      |> Enum.slide(0, -1)

    Changeset.put_assoc(changeset, :social_media_link_user, social_media)
  end

  defp remove_social_media_link_user(changeset, index) do
    social_media =
      List.delete_at(
        Changeset.get_change(
          changeset,
          :social_media_link_user,
          Changeset.get_field(changeset, :social_media_link_user, [])
        ),
        index
      )

    Changeset.put_assoc(changeset, :social_media_link_user, social_media)
  end

  defp set_delete_social_media_link_user(changeset, index) do
    social_media =
      List.update_at(
        Changeset.get_change(
          changeset,
          :social_media_link_user,
          Changeset.get_field(changeset, :social_media_link_user, [])
        ),
        index,
        &delete_social_media_change/1
      )

    Changeset.put_assoc(changeset, :social_media_link_user, social_media)
  end

  defp build_social_media(attrs \\ %{}) do
    %SocialMediaLinkUser{}
    |> Changeset.change()
    |> Changeset.put_assoc(
      :social_media_link,
      SocialMediaLink.cast_user_input(%SocialMediaLink{}, attrs)
    )
  end

  defp delete_social_media_change(media_link_user) do
    media_link = get_social_media_link(media_link_user)

    media_link_user
    |> Changeset.change()
    |> Changeset.put_assoc(
      :social_media_link,
      SocialMediaLink.cast_user_input(media_link, %{delete: true})
    )
  end

  defp get_social_media_link(%SocialMediaLinkUser{} = media_link_user) do
    Map.get(media_link_user, :social_media_link)
  end

  defp get_social_media_link(media_link_user) do
    Changeset.get_change(
      media_link_user,
      :social_media_link,
      Changeset.get_field(media_link_user, :social_media_link)
    )
  end

  defp build_social_media_changes([{_index, %{"social_media_link" => updated_link}} | params], [
         old_link | existing_social_media
       ]) do
    [
      old_link
      |> Changeset.change()
      |> Changeset.put_assoc(
        :social_media_link,
        SocialMediaLink.cast_user_input(old_link.social_media_link, updated_link)
      )
      | build_social_media_changes(params, existing_social_media)
    ]
  end

  defp build_social_media_changes(
         [{_index, %{"social_media_link" => updated_link}} | params],
         []
       ) do
    [build_social_media(updated_link) | build_social_media_changes(params, [])]
  end

  defp build_social_media_changes([], []), do: []

  defp is_graphical_designer?(user) do
    user.is_graphic_designer
  end

  defp render_badges(assigns) do
    keys = [
      :is_staff,
      :is_tournament_organizer,
      :is_pro,
      :is_caster,
      :is_graphic_designer,
      :is_producer
    ]

    badges =
      for key <- keys, Map.get(assigns.user, key, false) do
        "is_" <> badge = Atom.to_string(key)
        badge
      end

    assigns = assign(assigns, :badges, badges)

    ~H"""
    <%= for badge <- @badges do %>
      <img
        width="32"
        height="32"
        src={safe_static_url("/images/badge-#{badge}.svg")}
        title={badge_tooltip(badge) || humanize(badge)}
        alt={badge}
      />
    <% end %>
    """
  end

  defp badge_tooltip("staff"), do: "Stride Staff"
  defp badge_tooltip("pro"), do: "Player"
  defp badge_tooltip("tournament_organizer"), do: "Tournament Operator"
  defp badge_tooltip("graphic_designer"), do: "Graphic Designer"
  defp badge_tooltip(_), do: false
end
