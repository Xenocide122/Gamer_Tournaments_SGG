defmodule Strident.Repo.Local.Migrations.CreateUserRegionCodeCount do
  use Ecto.Migration

  def change do
    create table(:user_region_code_count, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :region_code, :string, null: false
      add :count, :integer, null: false

      timestamps()
    end

    create index(:user_region_code_count, [:user_id])
    create index(:user_region_code_count, [:region_code])
  end
end
