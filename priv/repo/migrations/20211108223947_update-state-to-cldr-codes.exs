defmodule :"Elixir.Strident.Repo.Migrations.Update-state-to-cldr-codes" do
  use Ecto.Migration

  def up do
    execute("UPDATE users set state = 'usal' where state = 'AL';")
    execute("UPDATE users set state = 'usak' where state = 'AK';")
    execute("UPDATE users set state = 'usaz' where state = 'AZ';")
    execute("UPDATE users set state = 'usar' where state = 'AR';")
    execute("UPDATE users set state = 'usca' where state = 'CA';")
    execute("UPDATE users set state = 'usco' where state = 'CO';")
    execute("UPDATE users set state = 'usct' where state = 'CT';")
    execute("UPDATE users set state = 'usde' where state = 'DE';")
    execute("UPDATE users set state = 'usfl' where state = 'FL';")
    execute("UPDATE users set state = 'usga' where state = 'GA';")
    execute("UPDATE users set state = 'ushi' where state = 'HI';")
    execute("UPDATE users set state = 'usid' where state = 'ID';")
    execute("UPDATE users set state = 'usil' where state = 'IL';")
    execute("UPDATE users set state = 'usin' where state = 'IN';")
    execute("UPDATE users set state = 'usia' where state = 'IA';")
    execute("UPDATE users set state = 'usks' where state = 'KS';")
    execute("UPDATE users set state = 'usky' where state = 'KY';")
    execute("UPDATE users set state = 'usla' where state = 'LA';")
    execute("UPDATE users set state = 'usme' where state = 'ME';")
    execute("UPDATE users set state = 'usmd' where state = 'MD';")
    execute("UPDATE users set state = 'usma' where state = 'MA';")
    execute("UPDATE users set state = 'usmi' where state = 'MI';")
    execute("UPDATE users set state = 'usmn' where state = 'MN';")
    execute("UPDATE users set state = 'usms' where state = 'MS';")
    execute("UPDATE users set state = 'usmo' where state = 'MO';")
    execute("UPDATE users set state = 'usmt' where state = 'MT';")
    execute("UPDATE users set state = 'usne' where state = 'NE';")
    execute("UPDATE users set state = 'usnv' where state = 'NV';")
    execute("UPDATE users set state = 'usnh' where state = 'NH';")
    execute("UPDATE users set state = 'usnj' where state = 'NJ';")
    execute("UPDATE users set state = 'usnm' where state = 'NM';")
    execute("UPDATE users set state = 'usny' where state = 'NY';")
    execute("UPDATE users set state = 'usnc' where state = 'NC';")
    execute("UPDATE users set state = 'usnd' where state = 'ND';")
    execute("UPDATE users set state = 'usoh' where state = 'OH';")
    execute("UPDATE users set state = 'usok' where state = 'OK';")
    execute("UPDATE users set state = 'usor' where state = 'OR';")
    execute("UPDATE users set state = 'uspa' where state = 'PA';")
    execute("UPDATE users set state = 'usri' where state = 'RI';")
    execute("UPDATE users set state = 'ussc' where state = 'SC';")
    execute("UPDATE users set state = 'ussd' where state = 'SD';")
    execute("UPDATE users set state = 'ustn' where state = 'TN';")
    execute("UPDATE users set state = 'ustx' where state = 'TX';")
    execute("UPDATE users set state = 'usut' where state = 'UT';")
    execute("UPDATE users set state = 'usvt' where state = 'VT';")
    execute("UPDATE users set state = 'usva' where state = 'VA';")
    execute("UPDATE users set state = 'uswa' where state = 'WA';")
    execute("UPDATE users set state = 'uswv' where state = 'WV';")
    execute("UPDATE users set state = 'uswi' where state = 'WI';")
    execute("UPDATE users set state = 'uswy' where state = 'WY';")
  end

  def down do
    execute("UPDATE users set state = 'AL' where state = 'usal';")
    execute("UPDATE users set state = 'AK' where state = 'usak';")
    execute("UPDATE users set state = 'AZ' where state = 'usaz';")
    execute("UPDATE users set state = 'AR' where state = 'usar';")
    execute("UPDATE users set state = 'CA' where state = 'usca';")
    execute("UPDATE users set state = 'CO' where state = 'usco';")
    execute("UPDATE users set state = 'CT' where state = 'usct';")
    execute("UPDATE users set state = 'DE' where state = 'usde';")
    execute("UPDATE users set state = 'FL' where state = 'usfl';")
    execute("UPDATE users set state = 'GA' where state = 'usga';")
    execute("UPDATE users set state = 'HI' where state = 'ushi';")
    execute("UPDATE users set state = 'ID' where state = 'usid';")
    execute("UPDATE users set state = 'IL' where state = 'usil';")
    execute("UPDATE users set state = 'IN' where state = 'usin';")
    execute("UPDATE users set state = 'IA' where state = 'usia';")
    execute("UPDATE users set state = 'KS' where state = 'usks';")
    execute("UPDATE users set state = 'KY' where state = 'usky';")
    execute("UPDATE users set state = 'LA' where state = 'usla';")
    execute("UPDATE users set state = 'ME' where state = 'usme';")
    execute("UPDATE users set state = 'MD' where state = 'usmd';")
    execute("UPDATE users set state = 'MA' where state = 'usma';")
    execute("UPDATE users set state = 'MI' where state = 'usmi';")
    execute("UPDATE users set state = 'MN' where state = 'usmn';")
    execute("UPDATE users set state = 'MS' where state = 'usms';")
    execute("UPDATE users set state = 'MO' where state = 'usmo';")
    execute("UPDATE users set state = 'MT' where state = 'usmt';")
    execute("UPDATE users set state = 'NE' where state = 'usne';")
    execute("UPDATE users set state = 'NV' where state = 'usnv';")
    execute("UPDATE users set state = 'NH' where state = 'usnh';")
    execute("UPDATE users set state = 'NJ' where state = 'usnj';")
    execute("UPDATE users set state = 'NM' where state = 'usnm';")
    execute("UPDATE users set state = 'NY' where state = 'usny';")
    execute("UPDATE users set state = 'NC' where state = 'usnc';")
    execute("UPDATE users set state = 'ND' where state = 'usnd';")
    execute("UPDATE users set state = 'OH' where state = 'usoh';")
    execute("UPDATE users set state = 'OK' where state = 'usok';")
    execute("UPDATE users set state = 'OR' where state = 'usor';")
    execute("UPDATE users set state = 'PA' where state = 'uspa';")
    execute("UPDATE users set state = 'RI' where state = 'usri';")
    execute("UPDATE users set state = 'SC' where state = 'ussc';")
    execute("UPDATE users set state = 'SD' where state = 'ussd';")
    execute("UPDATE users set state = 'TN' where state = 'ustn';")
    execute("UPDATE users set state = 'TX' where state = 'ustx';")
    execute("UPDATE users set state = 'UT' where state = 'usut';")
    execute("UPDATE users set state = 'VT' where state = 'usvt';")
    execute("UPDATE users set state = 'VA' where state = 'usva';")
    execute("UPDATE users set state = 'WA' where state = 'uswa';")
    execute("UPDATE users set state = 'WV' where state = 'uswv';")
    execute("UPDATE users set state = 'WI' where state = 'uswi';")
    execute("UPDATE users set state = 'WY' where state = 'uswy';")
  end
end
