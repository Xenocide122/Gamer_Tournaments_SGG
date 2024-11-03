defmodule Strident.Repo.Local.Migrations.RemoveWagerFrom_NJState do
  use Ecto.Migration

  def change do
    execute """
    DELETE FROM geographic_whitelists tmp0 where feature='wager' and region_code='usnj';
    """
  end
end
