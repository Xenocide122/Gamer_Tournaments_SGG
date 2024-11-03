defmodule Strident.Repo.Migrations.CreateStageSettingsTable do
  use Ecto.Migration

  def change do
    create table(:stage_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :stage_id, references(:stages, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :value, :map, null: false
      timestamps()
    end
  end
end
