defmodule Strident.Repo.Local.Migrations.AddSummaryFieldTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add(:summary, :string, size: 280)
    end
  end
end
