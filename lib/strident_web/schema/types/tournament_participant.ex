defmodule StridentWeb.Schema.Types.TournamentParticipant do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Strident.TournamentParticipants
  alias Strident.UrlGeneration
  alias StridentWeb.Schema.DataloaderUtils

  @desc """
  Someone who plays in a tournament, belongs to a TournamentParticipant
  """
  object :player do
    field(:id, non_null(:string))
    field(:user, :user_profile, resolve: dataloader(:data))
    field(:type, :string)
    field(:is_starter, :boolean)
  end

  @desc """
  A TournamentParticipant is an entity that participates in a tournament.
  It is associated with a Team or a Party.
  """
  object :tournament_participant do
    field(:id, non_null(:string))
    field(:status, non_null(:tournament_participant_status))

    @desc """
    A human-friendly "status" for labelling participants in UI
    """
    field :status_label, non_null(:string) do
      resolve(fn _, resolution ->
        %{context: %{loader: loader}, source: source} = resolution
        tournament = DataloaderUtils.get_via_loader(loader, :tournament, source)
        active_invitation = DataloaderUtils.get_via_loader(loader, :active_invitation, source)
        tps = DataloaderUtils.get_via_loader(loader, :participants, tournament)

        ranks_frequency =
          Enum.reduce(tps, %{}, fn %{rank: rank}, acc ->
            Map.update(acc, rank, 1, &(&1 + 1))
          end)

        active_invitation_status =
          case active_invitation do
            %{status: status} -> status
            _ -> nil
          end

        {:ok,
         TournamentParticipants.status_label(
           source.status,
           source.rank,
           tournament.status,
           active_invitation_status,
           ranks_frequency
         )}
      end)
    end

    field(:checked_in, non_null(:boolean))
    field(:rank, :integer)
    field(:players, list_of(non_null(:player)), resolve: dataloader(:data))
    field(:team, :team, resolve: dataloader(:data), resolve: dataloader(:data))
    field(:party, :party, resolve: dataloader(:data), resolve: dataloader(:data))
    field(:active_invitation, :tournament_invitation, resolve: dataloader(:data))

    @desc """
    Simply the next match this TP will play in. May be NULL.
    """
    field :next_match, :match do
      resolve(fn tp, _args, resolution ->
        tournament =
          DataloaderUtils.get_via_loader(
            resolution.context.loader,
            {:tournament, preload: [stages: [matches: :participants]]},
            tp
          )

        next_match = TournamentParticipants.next_match(tp, tournament)
        {:ok, next_match}
      end)
    end

    @desc """
    The next match this TournamentParticipant is required to report score. May be NULL.
    """
    field :next_match_requiring_report, :match do
      resolve(fn tp, _args, resolution ->
        tournament =
          DataloaderUtils.get_via_loader(
            resolution.context.loader,
            {:tournament, preload: [stages: [matches: [participants: :match_reports]]]},
            tp
          )

        next_match_requiring_report =
          TournamentParticipants.next_match_requiring_report(tp, tournament)

        {:ok, next_match_requiring_report}
      end)
    end

    field :logo_url, non_null(:string) do
      resolve(fn parent, _, _ ->
        parent
        |> TournamentParticipants.participant_logo_url()
        |> UrlGeneration.absolute_path()
        |> then(&{:ok, &1})
      end)
    end

    field :display_name, non_null(:string) do
      resolve(fn parent, _, _ ->
        parent
        |> TournamentParticipants.participant_name()
        |> then(&{:ok, &1})
      end)
    end

    field(:tournament, non_null(:tournament), resolve: dataloader(:data))

    @desc """
    The participant's given registration fields.
    """
    field(:registration_fields, list_of(non_null(:registration_field)), resolve: dataloader(:data))
  end

  object :list_of_tournament_participants do
    field(:entries, non_null(list_of(non_null(:tournament_participant))))
    field(:page_number, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:total_entries, :integer)
  end

  enum :tournament_participant_status do
    value(:empty,
      description:
        "The normal starting state of a TP. They are not associated with any Team/Party."
    )

    value(:invited, description: "A TP that has been invited, via email.")

    value(:contribution_to_entry_fee,
      description: "A TP that has accepted their invitation and is raising funds."
    )

    value(:chip_in_to_entry_fee,
      description: "A TP that has accepted their invitation and is allowing chip-ins."
    )

    value(:confirmed, description: "A TP that has accepted their invitation and is ready to play.")

    value(:dropped, description: "A TP that has been forsaken, rejected from the tournament.")
  end

  object :registration_field do
    field(:id, non_null(:string))
    field(:name, non_null(:string))
    field(:type, non_null(:registration_field_type))
    field(:value, non_null(:string))
  end

  @desc "Filtering options for TournamentParticipants"
  input_object :tournament_participant_filter do
    @desc "Matching the tournament ID"
    field(:tournament_id, :id)
    @desc "Matching the tournament_participant rank"
    field(:rank, :integer)
    @desc "Matching the tournament_participant status"
    field(:status, :tournament_participant_status)
  end
end
