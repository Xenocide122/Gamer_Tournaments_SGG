defmodule Strident.Repo.Migrations.AddStateAndAgeCheckToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :state, :string
      add :is_over_18, :boolean, null: true, default: false
    end
  end
end
