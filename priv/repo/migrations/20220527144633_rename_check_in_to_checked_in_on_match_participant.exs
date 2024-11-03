defmodule Strident.Repo.Migrations.RenameCheckInToCheckedInOnMatchParticipant do
  use Ecto.Migration

  def change do
    rename table(:match_participants), :check_in, to: :checked_in
  end
end
