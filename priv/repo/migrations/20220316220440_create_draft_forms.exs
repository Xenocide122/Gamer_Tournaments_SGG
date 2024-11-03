defmodule Strident.Repo.Migrations.CreateDraftForms do
  use Ecto.Migration

  def change do
    create table(:draft_forms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :form_type, :string, null: false
      add :data, :map
      timestamps()
    end

    create unique_index(:draft_forms, [:user_id, :form_type])
  end
end
