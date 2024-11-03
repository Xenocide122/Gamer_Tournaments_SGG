defmodule StridentWeb.Schema.Types.FormValidation do
  @moduledoc false
  use Absinthe.Schema.Notation

  enum :form_validation_attribute do
    @desc "If the field is required (boolean)"
    value(:required)
    @desc "max number"
    value(:max)
    @desc "min number"
    value(:min)
    @desc "number input step"
    value(:step)
    @desc "max string length"
    value(:maxlength)
    @desc "min string length"
    value(:minlength)

    @desc """
    PCRE regex pattern for string to match
    The client will need to convert this into a JS regex.
    Use, e.g. https://github.com/TooTallNate/pcre-to-regexp
    """
    value(:format)
  end

  @desc """
  A HTML form validation attribute and value
  https://developer.mozilla.org/en-US/docs/Learn/Forms/Form_validation
  Note the value is always a string. This means booleans must be parsed.
  """
  object :form_validation do
    field :attribute, non_null(:form_validation_attribute)
    field :value, non_null(:string)
    field :message, :string
  end
end
