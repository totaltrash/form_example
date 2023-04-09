defmodule MyApp.Grocery do
  use Ash.Api

  resources do
    registry MyApp.Grocery.Registry
  end
end
