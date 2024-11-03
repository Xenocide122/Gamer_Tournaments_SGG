defmodule Strident.Repo.Local.Migrations.CreateTableChats do
  use Ecto.Migration

  def change do
    create table(:chats, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :room_name, :string

      timestamps()
    end

    unique_index(:chats, [:room_name], name: :chats_room_name_index)
  end
end
