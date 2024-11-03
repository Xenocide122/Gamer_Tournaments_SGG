defmodule Strident.Repo.Local.Migrations.UpdateGeographicWhitelistGatewayOptions do
  use Ecto.Migration

  def change do
    execute """
    UPDATE geographic_whitelists SET gateway_options ='{paypal}';
    """
  end
end
