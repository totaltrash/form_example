# One-to-many form example using AshPhoenix

An example of building a one-to-many form using [AshPhoenix.Form](https://ash-hq.org/docs/module/ash_phoenix/latest/ashphoenix-form).

![Example](https://raw.githubusercontent.com/totaltrash/form_example/master/artifacts/screenshot.png?raw=true)

I was inspired by [this excellent post by Benjamin Milde](https://kobrakai.de/kolumne/one-to-many-liveview-form) which describes using Ecto changesets to add and remove lines to a one-to-many form, and the form validation and submission. I wanted to build an equivalent form using `AshPhoenix.Form`. Ash's mantra is to "model your domain, derive the rest", and this example shows how modelling relationships in your resources can then be used by tools such as `AshPhoenix.Form` to make light work of adding and removing nested forms, and handling form validation and submission.

## Model your domain

There are two elements in the resources that enable AshPhoenix to do its work; the relationship itself and the action that creates (or updates) the parent resource and manages that relationship:

```elixir
# The parent resource
defmodule MyApp.Grocery.Order do
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  relationships do
    has_many :items, MyApp.Grocery.Item do
      destination_attribute :order_id
    end
  end

  actions do
    create :create do
      argument :items, {:array, :map}
      change manage_relationship(:items, type: :create)
    end
  end
end

# The child resource
defmodule MyApp.Grocery.Item do
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  relationships do
    belongs_to :order, MyApp.Grocery.Order do
      allow_nil? false
    end
  end

  actions do
    defaults([:create, :read, :update, :destroy])
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :amount, :integer, allow_nil?: false
  end
end

```

## Derive the rest

With the domain modelled, we can now use `AshPhoenix.Form` to create a form (which implements `Phoenix.HTML.FormData`), and use that in the normal Phoenix way to generate a `Phoenix.HTML.Form` (using `to_form`).

```elixir
form =
  MyApp.Grocery.Order
  |> AshPhoenix.Form.for_create(:create,
    api: MyApp.Grocery,
    forms: [auto?: true]
  )
  |> AshPhoenix.Form.add_form([:items], params: %{"name" => "Melon", "amount" => 1})
  |> AshPhoenix.Form.add_form([:items], params: %{"name" => "Grapes", "amount" => 3})
  |> to_form()
```

In the example above, `forms: [auto?: true]` indicates that the nested forms are to be derived purely by the `:create` action. Arguments expected by the `:create` action (`:items` in this instance) are used to generate the nested forms structure. The nested forms can also be manually provided:

```elixir
MyApp.Grocery.Order
|> AshPhoenix.Form.for_create(:create,
  api: MyApp.Grocery,
  forms: [
    items: [
      type: :list,
      resource: MyApp.Grocery.Item,
      create_action: :create
    ]
  ]
)
```

As our generated form is a `Phoenix.HTML.Form` we can render it in the normal Phoenix fashion, using `.inputs_for` to render our nested forms (which also takes care of rendering hidden fields associated with the nested forms), and provide buttons to add and remove our nested items:

```heex
<.simple_form for={@form} phx-change="validate" phx-submit="submit">
  <%!-- Attributes for the parent resource --%>
  <.input type="email" label="Email" field={@form[:email]} />
  <%!-- Render nested forms for related data --%>
  <.inputs_for :let={item_form} field={@form[:items]}>
    <.input type="text" label="Item" field={item_form[:name]} />
    <.input type="number" label="Amount" field={item_form[:amount]} />
    <.button type="button" phx-click="remove_form" phx-value-path={item_form.name}>
      Remove
    </.button>
  </.inputs_for>
  <:actions>
    <.button type="button" phx-click="add_form" phx-value-path={@form[:items].name}>
      Add Item
    </.button>
    <.button>Save</.button>
  </:actions>
</.simple_form>
```

Where AshPhoenix is different to using Ecto changesets, is that it the form is stateful and expects you to store the form definition into assigns and reuse it on validation, form submission, or when adding and removing nested forms:

```elixir
def handle_event("add_form", %{"path" => path}, socket) do
  {:noreply, assign(socket, form: AshPhoenix.Form.add_form(socket.assigns.form, path))}
end

def handle_event("remove_form", %{"path" => path}, socket) do
  {:noreply, assign(socket, form: AshPhoenix.Form.remove_form(socket.assigns.form, path))}
end

def handle_event("validate", %{"form" => params}, socket) do
  {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, params))}
end

def handle_event("submit", %{"form" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
    {:ok, order} ->
      {:noreply,
        socket
        |> put_flash(:info, "Saved order for #{order.email}!")
        |> push_navigate(to: ~p"/")}

    {:error, form} ->
      {:noreply, assign(socket, form: form)}
  end
end
```

## Troubleshooting

There are a few gotchas. You need to ensure that the domain is modelled correctly, which sounds obvious but it can sometimes be tricky to identify what's broken when your nested forms are not working as expected during development. When I'm stuck, I find that I need to pay attention to two things:

1. Am I using the correct manage_relationship `:type` in the parent resource? Depending on the type of relationship, I tend to start with `:create` on create actions and `:direct_control` on update actions. 

2. Are the create, update and destroy actions on the child resource appropriate? When specifying a `type` to [`manage_relationship`](https://ash-hq.org/docs/module/ash/latest/ash-changeset#function-manage_relationship-4), it will use the primary actions on the child resources. If those primary actions expect non-nil arguments, form validation will not pass (and errors may not be displayed in the form as those arguments are not represented as fields on the form). To fix this, you can either ensure the primary actions on the child resource expect no arguments (like the default actions), or modify the `manage_relationship` on the parent to not use a `type` but use the finer grained options (`on_no_match`, `on_lookup`...) to specify which action to use to create, update or destroy children (`on_no_match: {:create, :create_action_with_no_args}`)
