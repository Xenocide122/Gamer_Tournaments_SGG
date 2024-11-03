defmodule Strident.Repo.Local.Migrations.AddPaymentOptionColGeographicWhitelists do
  use Ecto.Migration

  def change do
    alter table(:geographic_whitelists) do
      add :gateway_options, {:array, :string}
    end

    execute """
    UPDATE geographic_whitelists SET gateway_options ='{paypal,ach}' WHERE country_code = 'us';
    """

    execute """
    UPDATE geographic_whitelists SET gateway_options ='{paypal}' WHERE country_code != 'us';
    """

    alter table(:geographic_whitelists) do
      modify :gateway_options, {:array, :string}, null: false
    end
  end
end
