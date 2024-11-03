defmodule Strident.Repo.Migrations.AddLogoUrlToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add :logo_url, :string
    end
  end
end
