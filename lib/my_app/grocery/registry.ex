defmodule MyApp.Grocery.Registry do
  use Ash.Registry,
    extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry MyApp.Grocery.Order
    entry MyApp.Grocery.Item
  end
end
