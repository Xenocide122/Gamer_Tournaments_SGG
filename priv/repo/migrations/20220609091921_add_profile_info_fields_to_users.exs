defmodule Strident.Repo.Migrations.AddProfileInfoFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :real_name, :string, null: true
      add :location, :string, null: true
      add :birthday, :naive_datetime, null: true

      add :primary_team_id, references(:teams, on_delete: :nilify_all, type: :binary_id),
        null: true
    end
  end
end
