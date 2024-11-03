defmodule Strident.Repo.Migrations.AddProfileUrlToPros do
  use Ecto.Migration

  def change do
    alter table(:pros) do
      add :profile_url, :string, null: true
    end

    create unique_index(:pros, [:profile_url])

    execute("update pros set profile_url=twitch_handle")

    alter table(:pros) do
      modify :profile_url, :string, null: false
    end
  end
end
