defmodule StridentWeb.SearchLive do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.Teams
  alias Strident.Teams.Team
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias StridentWeb.Endpoint
  alias StridentWeb.SegmentAnalyticsHelpers

  @empty_results %{
    total_results: 0,
    teams: [],
    users: []
  }

  @min_search_string_length 3

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container w-full pt-12 md:pt-44 md:max-w-screen-md">
      <form id="search-live-search-form" phx-change="search" phx-submit="search">
        <input
          phx-debounce="300"
          class="form-input mb-14"
          name="search_term"
          type="text"
          value={@search_term}
          autocomplete="off"
          placeholder="Search for your favorite players, teams and users."
        />
      </form>

      <%= if @search_term != "" && String.length(@search_term) >= 3 do %>
        <h1 class="font-display text-primary">
          Results for " <%= @search_term %> "
        </h1>

        <p class="text-grey-light mb-14">
          Showing <%= @search_results.total_results %> results
        </p>
      <% else %>
        <h1 class="font-display text-primary">
          Search
        </h1>

        <p class="text-grey-light mb-14">
          Search for your favorite players, teams, users or tournaments.
        </p>
      <% end %>

      <%= for key <- [:teams, :users, :tournaments], has_results?(@search_results, key) do %>
        <h2 class="mb-8">
          <%= humanize(key) %>
        </h2>

        <div class="mb-14">
          <%= for value <- Map.get(@search_results, key) do %>
            <.search_result_item current_user={@current_user} item={value} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(%{"search_term" => search_term} = _params, _session, socket) do
    socket
    |> do_search(search_term)
    |> then(&{:ok, &1})
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(%{
        page_title: "Search",
        search_term: "",
        search_results: @empty_results
      })

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  @impl true
  def handle_event("search", %{"search_term" => search_term}, socket) do
    socket =
      if String.length(search_term) >= @min_search_string_length do
        do_search(socket, search_term)
      else
        socket
        |> assign(%{
          search_term: search_term,
          search_results: @empty_results
        })
      end

    {:noreply, push_patch(socket, to: self_path(socket, search_term))}
  end

  @impl true
  def handle_event(
        "follow-user",
        %{"user" => user_id},
        %{assigns: %{current_user: current_user, search_results: search_results}} = socket
      ) do
    case current_user && Accounts.follow_user(user_id, current_user.id) do
      {:ok, _following} ->
        %{users: users} = search_results

        users =
          Enum.map(users, fn
            %{id: id} = user when user_id == id ->
              %{user | followers: [current_user | user.followers]}

            user ->
              user
          end)

        {:noreply, assign(socket, :search_results, %{search_results | users: users})}

      _ ->
        {:noreply, put_flash(socket, :error, "Cannot follow user")}
    end
  end

  @impl true
  def handle_event(
        "follow-team",
        %{"team" => team_id},
        %{assigns: %{current_user: current_user, search_results: search_results}} = socket
      ) do
    case current_user && Teams.follow_team(team_id, current_user.id) do
      {:ok, _team_follower} ->
        %{teams: teams} = search_results

        teams =
          Enum.map(teams, fn
            %{id: id} = team when team_id == id ->
              %{team | followers: [current_user | team.followers]}

            team ->
              team
          end)

        {:noreply, assign(socket, :search_results, %{search_results | teams: teams})}

      _ ->
        {:noreply, put_flash(socket, :error, "Cannot unfollow team")}
    end
  end

  @impl true
  def handle_event(
        "unfollow-user",
        %{"user" => user_id},
        %{assigns: %{current_user: current_user, search_results: search_results}} = socket
      ) do
    case current_user && Accounts.unfollow_user(user_id, current_user.id) do
      {:ok, _following} ->
        %{users: users} = search_results

        users =
          Enum.map(users, fn
            %{id: id} = user when user_id == id ->
              followers = Enum.reject(user.followers, &(&1.id == current_user.id))
              %{user | followers: followers}

            user ->
              user
          end)

        {:noreply, assign(socket, :search_results, %{search_results | users: users})}

      _ ->
        {:noreply, put_flash(socket, :error, "Cannot unfollow user")}
    end
  end

  @impl true
  def handle_event(
        "unfollow-team",
        %{"team" => team_id},
        %{assigns: %{current_user: current_user, search_results: search_results}} = socket
      ) do
    case current_user && Teams.unfollow_team(team_id, current_user.id) do
      {:ok, _team_follower} ->
        %{teams: teams} = search_results

        teams =
          Enum.map(teams, fn
            %{id: id} = team when team_id == id ->
              followers = Enum.reject(team.followers, &(&1.id == current_user.id))
              %{team | followers: followers}

            team ->
              team
          end)

        {:noreply, assign(socket, :search_results, %{search_results | teams: teams})}

      _ ->
        {:noreply, put_flash(socket, :error, "Cannot unfollow team")}
    end
  end

  def self_path(socket, params) do
    Routes.live_path(socket, __MODULE__, params)
  end

  attr :item, :any, default: nil
  attr :current_user, User, default: nil

  def search_result_item(%{item: %User{}} = assigns) do
    ~H"""
    <div class="flex items-center justify-between border-b-[1px] border-grey-light py-3 last:border-b-0">
      <.search_title
        image_url={Accounts.avatar_url(@item)}
        title={@item.display_name}
        redirection_url={Routes.user_show_path(Endpoint, :show, @item.slug)}
      />

      <.show_button
        current_user={@current_user}
        user={@item}
        user_followers_ids={Enum.map(@item.followers, & &1.id)}
      />
    </div>
    """
  end

  def search_result_item(%{item: %Team{}} = assigns) do
    ~H"""
    <div class="flex items-center justify-between border-b-[1px] border-grey-light py-3 last:border-b-0">
      <.search_title
        image_url={@item.logo_url}
        title={@item.name}
        redirection_url={Routes.live_path(Endpoint, StridentWeb.TeamProfileLive.Show, @item.slug)}
      />

      <.show_button
        current_user={@current_user}
        team={@item}
        team_followers_ids={Enum.map(@item.followers, & &1.id)}
      />
    </div>
    """
  end

  def search_result_item(%{item: %Tournament{}} = assigns) do
    ~H"""
    <div class="flex items-center justify-between border-b-[1px] border-grey-light py-3 last:border-b-0">
      <.search_title
        image_url={Tournaments.cover_img_url(@item)}
        title={@item.title}
        redirection_url={Routes.tournament_show_pretty_path(Endpoint, :show, @item.slug)}
      />
    </div>
    """
  end

  attr :redirection_url, :string, required: true
  attr :image_url, :string, required: true
  attr :title, :string, required: true

  def search_title(assigns) do
    ~H"""
    <div class="flex items-center">
      <.link navigate={@redirection_url} class="mr-4">
        <img class="rounded-full" src={@image_url} height="30" width="30" />
      </.link>

      <.link navigate={@redirection_url} class="grow text-primary">
        <%= @title %>
      </.link>
    </div>
    """
  end

  attr :current_user, User, default: nil
  attr :team, Team, default: nil
  attr :user, User, default: nil
  attr :user_followers_ids, :list, default: []
  attr :team_followers_ids, :list, default: []

  def show_button(%{current_user: nil} = assigns) do
    ~H"""
    <.link
      id="login-page"
      navigate={Routes.live_path(Endpoint, StridentWeb.UserLogInLive)}
      class="btn btn--primary"
    >
      Follow
    </.link>
    """
  end

  def show_button(%{team: %Team{}} = assigns) do
    ~H"""
    <div>
      <button
        :if={@current_user.id in @team_followers_ids}
        class="inline-flex items-center justify-center py-[1px] px-[1px] overflow-hidden rounded group bg-gradient-to-br from-grilla-blue to-grilla-pink group-hover:from-grilla-blue group-hover:to-grilla-pink hover:text-white uppercase"
        phx-click="unfollow-team"
        phx-value-team={@team.id}
      >
        <span class="bg-blackish py-1.5 px-2.5 rounded">
          Following
        </span>
      </button>

      <button
        :if={@current_user.id not in @team_followers_ids}
        class="btn btn--primary py-1.5 px-2.5"
        phx-click="follow-team"
        phx-value-team={@team.id}
      >
        Follow
      </button>
    </div>
    """
  end

  def show_button(%{user: %User{}} = assigns) do
    ~H"""
    <div>
      <button
        :if={@current_user.id in @user_followers_ids and @current_user.id != @user.id}
        class="inline-flex items-center justify-center py-[1px] px-[1px] overflow-hidden rounded group bg-gradient-to-br from-grilla-blue to-grilla-pink group-hover:from-grilla-blue group-hover:to-grilla-pink hover:text-white uppercase"
        phx-click="unfollow-user"
        phx-value-user={@user.id}
      >
        <span class="bg-blackish py-1.5 px-2.5 rounded">
          Following
        </span>
      </button>

      <button
        :if={@current_user.id not in @user_followers_ids and @current_user.id != @user.id}
        class="btn btn--primary py-1.5 px-2.5"
        phx-click="follow-user"
        phx-value-user={@user.id}
      >
        Follow
      </button>
    </div>
    """
  end

  def has_results?(search_results, schema) do
    search_results
    |> Map.get(schema, [])
    |> Enum.any?()
  end

  defp do_search(socket, search_term) do
    if String.length(search_term) >= @min_search_string_length do
      user_id =
        case socket do
          %{assigns: %{current_user: %{id: id}}} -> id
          _ -> nil
        end

      Logger.info("Doing search for: #{search_term}", %{user_id: user_id})
      results = Strident.Search.search_all(search_term, users_opts: [preload: :followers])

      socket
      |> SegmentAnalyticsHelpers.track_segment_event("Search Page Searched", %{
        search_term: search_term
      })
      |> assign(%{
        search_term: search_term,
        search_results: results
      })
    else
      assign(socket, %{
        search_term: search_term,
        search_results: @empty_results
      })
    end
  end
end
