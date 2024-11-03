defmodule StridentWeb.Schema.Types.Tournament do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Strident.Accounts.User
  alias Strident.Tournaments
  alias Strident.UrlGeneration
  alias StridentWeb.Router.Helpers, as: Routes
  alias StridentWeb.Schema.DataloaderUtils

  object :list_of_tournaments do
    field(:entries, list_of(non_null(:tournament)))
    field(:page_number, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:total_entries, :integer)
  end

  @desc "A Tournament within our system."
  object :tournament do
    field(:id, non_null(:string))

    @desc """
    There are 2 types of tournament:

    - `casting_call`: In an casting_call tournament, anyone can make a team/party and become a “tournament participant”.
    In theory, it could have thousands of participants.
    A participant becomes a “confirmed” when their entry fee is fully paid.

    - `invite_only`: In a invite_only tournament, all the tournament participants are pre-selected.
    """
    field(:type, non_null(:tournament_type))
    field(:starts_at, non_null(:naive_datetime))
    field(:title, non_null(:string))
    field(:slug, non_null(:string))

    field :cover_image_url, :string do
      resolve(fn _, %{context: %{loader: loader}, source: source} = resolution ->
        case resolution.source.cover_image_url do
          nil ->
            game = DataloaderUtils.get_via_loader(loader, :game, source)
            {:ok, game.default_game_banner_url}

          cover_image_url when is_binary(cover_image_url) ->
            {:ok, cover_image_url}
        end
      end)
    end

    field :thumbnail_image_url, :string do
      resolve(fn _, %{context: %{loader: loader}, source: source} = resolution ->
        case resolution.source.thumbnail_image_url do
          nil ->
            game = DataloaderUtils.get_via_loader(loader, :game, source)
            {:ok, game.default_game_banner_url}

          thumbnail_image_url when is_binary(thumbnail_image_url) ->
            {:ok, thumbnail_image_url}
        end
      end)
    end

    field(:buy_in_amount, non_null(:money))
    field(:prize_strategy, non_null(:prize_strategy))
    field(:prize_pool, non_null(:json))
    field(:prize_distribution, non_null(:json))

    field(:status, non_null(:tournament_status))
    field(:allow_staking, non_null(:string))
    field(:game, non_null(:game), resolve: dataloader(:data))
    field(:deleted_at, :naive_datetime)
    field(:required_participant_count, :integer)

    field :participant_type, :string do
      resolve(fn _, resolution ->
        if resolution.source.players_per_participant > 1 do
          {:ok, :team}
        else
          {:ok, :individual}
        end
      end)
    end

    field(:players_per_participant, :integer)
    field(:twitch_channel, :string)
    field(:registrations_open_at, :naive_datetime)
    field(:registrations_close_at, :naive_datetime)
    field(:description, :string)
    field(:rules, :string)
    field(:website, :string)
    field(:contact_email, :string)
    field(:show_contact_email, :string)
    field(:featured, :string)
    field(:platform, :string)
    field(:location, :tournament_location)
    field(:full_address, :string)
    field(:is_public, :string)

    @desc """
    The tournament organizer.
    """
    field(:created_by, non_null(:user), resolve: dataloader(:data))

    field :stages, list_of(:stage) do
      arg(:filter, :stage_filter)
      resolve(dataloader(:data))
    end

    field :participants, :list_of_tournament_participants do
      resolve(fn _, _, resolution ->
        DataloaderUtils.paginated_assoc(resolution, [:participants])
      end)
    end

    @desc """
    A link to a view of the tournament's stages as bracket graphs
    """
    field :brackets_graph_url, :string do
      resolve(fn tournament, _, _resolution ->
        StridentWeb.Endpoint
        |> Routes.tournament_bracket_and_seeding_web_view_path(
          :index,
          tournament.slug
        )
        |> UrlGeneration.absolute_path()
        |> then(&{:ok, &1})
      end)
    end

    @desc """
    The current user's TournamentParticipant, if they are playing in the tournament

    Includes, e.g. match reporting
    """
    field :my_participant, :tournament_participant do
      resolve(fn tournament, _, resolution ->
        case resolution do
          %{context: %{current_user: %{id: user_id}, loader: loader}} ->
            tps =
              DataloaderUtils.get_via_loader(
                loader,
                {:participants, [filter: %{players: %{user: %{id: user_id}}}]},
                tournament
              )

            tp = Enum.find(tps, &(&1.status in Tournaments.on_track_statuses()))
            {:ok, tp}

          _ ->
            {:ok, nil}
        end
      end)
    end

    @desc """
    Returns User Tournament Invitations.
    """
    field :my_tournament_invitation, :tournament_invitation do
      resolve(fn tournament, _, resolution ->
        %{current_user: user} = resolution.context
        {:ok, Tournaments.get_users_tournament_pending_invitation(user, tournament)}
      end)
    end

    @desc """
    Is registration still opened.
    """
    field :open_registration, non_null(:boolean) do
      resolve(fn
        %{type: :casting_call} = tournament, _, _ ->
          is_nil(tournament.required_participant_count) ||
            tournament.required_participant_count >
              Tournaments.get_number_of_confirmed_participants(tournament)

        %{type: :invite_only}, _, _ ->
          false
      end)
    end

    @desc """
    Returns needed registration fields for registration for tournament.
    """
    field(:registration_fields, list_of(non_null(:tournament_registration_field)),
      resolve: dataloader(:data)
    )

    @desc """
    Returns Current User Party Invitations.
    """
    field :my_party_invitations, list_of(non_null(:party_invitation)) do
      resolve(fn tournament, _, resolution ->
        case resolution.context do
          %{current_user: %User{} = user} ->
            {:ok, Strident.Rosters.get_users_roster_invites(tournament.id, user)}

          _ ->
            {:ok, []}
        end
      end)
    end
  end

  object :tournament_registration_field do
    field(:id, non_null(:string))
    field(:field_name, non_null(:string))
    field(:field_type, non_null(:registration_field_type))
  end

  enum :registration_field_type do
    @desc """
    Description:
    - `:text` - is just normal text component
    - `:text_box` - is text box area user can input a lot of things.
    """
    value(:text)
    value(:text_box)
  end

  enum :tournament_status do
    @desc """
    Tournament can have one of the statuses:
    - `scheduled`: means tournament is currently accepting entries from participants
    - `registrations_open`: means tournament is open for registration and matches/participants can not be switched/changed any more
    - `registrations_closed`: shortly before tournament starts, this is where we create all the matches and TO has time to switch participants.
    - `in_progress`: means tournament is currently ongoing
    - `under_review`: means tournament has no further stages or matches to play and participant ranks are "unofficial"
    - `finished`: means participant ranks are "official"
    - `cancelled`: status means touranment was cancelled and none of the participants will be played (everyone is refunded)

    A tournament of type `invite_only` will usually have this life:
    reg open -> reg closed -> in progress -> under review -> finished

    A tournament of type `casting_call` will usually have this life:
    scheduled -> reg open -> reg closed -> in progress -> under review -> finished
    """
    value(:scheduled)
    value(:registrations_open)
    value(:registrations_closed)
    value(:in_progress)
    value(:under_review)
    value(:finished)
    value(:cancelled)
  end

  enum :prize_strategy do
    value(:prize_pool)
    value(:prize_distribution)
  end

  enum :tournament_type do
    @desc """
    - `casting_call`: In an casting_call tournament, anyone can make a team/party and become a “tournament participant”.
    In theory, it could have thousands of participants.
    However, the tournament has a required_participant_count and only that many can
    actually participate in the tournament.
    A participant becomes an “actual participant” when their entry fee is fully paid.
    When required_participant_count participants are confirmed, we don’t allow any more registration.
    Unsuccessful participants have their contributors refunded and the tournament can begin.

    - `invite_only`: In a invite_only tournament, all the tournament participants are pre-selected and
    guaranteed to actually participate in the tournament.
    The tournament participants are placed into their initial (round=0) stage matches
    and each participant’s team/party captain sets their team/party’s split,
    which determines how much of the prize_pool goes to backers.
    """
    value(:invite_only)
    value(:casting_call)
  end

  enum :tournament_location do
    value(:online)
    value(:offline)
  end
end
