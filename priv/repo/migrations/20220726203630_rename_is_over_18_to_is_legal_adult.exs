defmodule Strident.Repo.Migrations.RenameIsOver18ToIsLegalAdult do
  use Ecto.Migration

  def change do
    rename table(:users), :is_over_18, to: :is_legal_adult
  end
end
