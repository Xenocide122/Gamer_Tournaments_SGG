defmodule StridentWeb.TournamentPageLive.AssignTransformer do
  @moduledoc """
  Functions for tranforming tournament assigns when handling PubSub broadcasts
  """
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.Stages
  alias Strident.Tournaments.Tournament
  alias StridentWeb.TournamentManagment.Setup

  @doc """
  Takes the given result of creating a match participant and fully transforms the nested
  Tournament struct accordingly.
  """
  @spec transform_tournament_assign_with_created_match_participant(Tournament.t(), map()) ::
          Tournament.t()
  def transform_tournament_assign_with_created_match_participant(tournament, %{
        match_participant:
          %MatchParticipant{match: %{id: match_id, stage: %{id: stage_id}}} = match_participant
      }) do
    updated_stages =
      Enum.map(tournament.stages, fn stage ->
        if stage.id == stage_id do
          updated_matches =
            Enum.map(stage.matches, fn match ->
              if match.id == match_id do
                updated_participants = [match_participant | match.participants]
                %{match | participants: updated_participants}
              else
                match
              end
            end)

          %{stage | matches: updated_matches}
        else
          stage
        end
      end)

    %{tournament | stages: updated_stages}
  end

  @doc """
  Takes the given result of deleting a match participant and fully transforms the nested
  Tournament struct accordingly.
  """
  @spec transform_tournament_assign_with_deleted_match_participant(Tournament.t(), map()) ::
          Tournament.t()
  def transform_tournament_assign_with_deleted_match_participant(tournament, %{
        match_participant: %MatchParticipant{
          id: match_participant_id,
          match: %{id: match_id, stage: %{id: stage_id}}
        }
      }) do
    updated_stages =
      Enum.map(tournament.stages, fn stage ->
        if stage.id == stage_id do
          updated_matches =
            Enum.map(stage.matches, fn match ->
              if match.id == match_id do
                updated_participants =
                  Enum.reject(match.participants, &(&1.id == match_participant_id))

                %{match | participants: updated_participants}
              else
                match
              end
            end)

          %{stage | matches: updated_matches}
        else
          stage
        end
      end)

    %{tournament | stages: updated_stages}
  end

  @doc """
  Takes the given result of updating a match participant and fully transforms the nested
  Tournament struct accordingly.
  """
  @spec transform_tournament_assign_with_updated_match_participant(Tournament.t(), map()) ::
          Tournament.t()
  def transform_tournament_assign_with_updated_match_participant(tournament, %{
        match_participant:
          %{id: match_participant_id, match: %{id: match_id, stage: %{id: stage_id}}} =
            match_participant
      }) do
    updated_stages =
      Enum.map(tournament.stages, fn stage ->
        if stage.id == stage_id do
          updated_matches =
            Enum.map(stage.matches, fn match ->
              if match.id == match_id do
                updated_participants =
                  Enum.map(match.participants, fn participant ->
                    if participant.id == match_participant_id do
                      match_participant
                    else
                      participant
                    end
                  end)

                %{match | participants: updated_participants}
              else
                match
              end
            end)

          %{stage | matches: updated_matches}
        else
          stage
        end
      end)

    %{tournament | stages: updated_stages}
  end

  @doc """
  Takes the given result of marking a match winner and fully transforms the nested
  Tournament struct accordingly. It should create/update maches, edges and participants.
  """
  @spec transform_tournament_assign_with_match_winner(Tournament.t(), map()) :: Tournament.t()
  def transform_tournament_assign_with_match_winner(tournament, %{
        stage_id: stage_id,
        match_id: match_id,
        updated_winners: updated_winners,
        child_matches: child_matches,
        child_participants: child_participants
      }) do
    updated_stages =
      Enum.map(tournament.stages, fn stage ->
        if stage.id == stage_id do
          if Enum.any?(stage.matches, &(&1.id == match_id)) do
            Enum.reduce(updated_winners, stage, fn updated_winner, stage ->
              update_stage(stage, match_id, updated_winner, child_matches, child_participants)
            end)
          else
            Stages.get_stage_with_preloads_by([id: stage_id], Setup.stage_full_preloads())
          end
        else
          stage
        end
      end)

    %{tournament | stages: updated_stages}
  end

  defp update_stage(
         stage,
         parent_match_id,
         updated_winner,
         child_matches,
         child_participants
       ) do
    parent = Enum.find(stage.matches, &(&1.id == parent_match_id))
    existing_match_ids = Enum.map(stage.matches, & &1.id)

    {child_matches_to_update, child_matches_to_add} =
      Enum.split_with(child_matches, &(&1.id in existing_match_ids))

    child_matches_to_update_ids = Enum.map(child_matches_to_update, & &1.id)

    updated_matches =
      Enum.map(stage.matches, fn
        %{id: ^parent_match_id} = match ->
          update_parent_match(match, updated_winner)

        match ->
          if match.id in child_matches_to_update_ids do
            update_child_match(match, parent_match_id, child_matches, child_participants)
          else
            match
          end
      end)

    child_participants_by_match_ids = Enum.group_by(child_participants, & &1.match_id)
    new_matches = get_new_matches(child_matches_to_add, parent, child_participants_by_match_ids)
    %{stage | matches: new_matches ++ updated_matches}
  end

  defp update_parent_match(%{participants: participants} = match, updated_winner) do
    updated_winners =
      Enum.map(
        participants,
        &if(&1.id == updated_winner.id, do: updated_winner, else: &1)
      )

    %{match | participants: updated_winners}
  end

  defp update_child_match(match, parent_match_id, child_matches, child_participants) do
    new_participants = Enum.filter(child_participants, &(&1.match_id == match.id))

    new_edges =
      case Enum.find(match.parent_edges, &(&1.parent_id == parent_match_id)) do
        nil ->
          child_matches
          |> Enum.find(&(&1.id == match.id))
          |> then(fn %{parent_edges: parent_edges} ->
            Enum.filter(parent_edges, &(&1.parent_id == parent_match_id))
          end)

        _edge ->
          []
      end

    %{
      match
      | participants: new_participants ++ match.participants,
        parent_edges: new_edges ++ match.parent_edges
    }
  end

  defp get_new_matches(child_matches_to_add, parent, child_participants_by_match_ids) do
    Enum.map(
      child_matches_to_add,
      &%{&1 | parents: [parent], participants: Map.get(child_participants_by_match_ids, &1.id)}
    )
  end
end
