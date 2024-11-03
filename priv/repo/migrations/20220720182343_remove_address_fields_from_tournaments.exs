defmodule Strident.Repo.Migrations.RemoveAddressFieldsFromTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      remove :address
      remove :city
      remove :state
      remove :postal_code
    end
  end
end
