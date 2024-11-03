defmodule Strident.Repo.Local.Migrations.CreateTableMatchChats do
  use Ecto.Migration

  def change do
    create table(:match_chats, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :chat_id, references(:chats, on_delete: :delete_all, type: :binary_id)
      add :match_id, references(:matches, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end
  end
end
