defmodule Strident.Repo.Local.Migrations.RefineDraftFormsUserIdFormTypeUniqueIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:draft_forms, [:user_id, :form_type])

    create unique_index(:draft_forms, [:user_id, :form_type],
             where: "is_saved = false or is_saved IS NULL"
           )
  end
end
