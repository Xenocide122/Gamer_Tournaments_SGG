defmodule Strident.Repo.Local.Migrations.CreateMinecraftServers do
  use Ecto.Migration

  def change do
    create table(:minecraft_servers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :img_url, :string, null: false
      add :external_url, :string, null: false
      add :title, :string, null: false
      add :categories, {:array, :string}, null: false
      timestamps()
    end
  end
end
