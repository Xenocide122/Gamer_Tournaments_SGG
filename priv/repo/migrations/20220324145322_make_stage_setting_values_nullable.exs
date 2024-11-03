defmodule Strident.Repo.Migrations.MakeStageSettingValuesNullable do
  use Ecto.Migration

  def change do
    alter table(:stage_settings) do
      modify :value, :map, null: true
    end
  end
end
