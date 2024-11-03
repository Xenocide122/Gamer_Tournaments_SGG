defmodule Strident.Repo.Local.Migrations.CreateTableMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :chat_id, references(:chats, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :content, :text
      add :edited_at, :utc_datetime
      add :deleted_at, :utc_datetime

      timestamps()
    end
  end
end
