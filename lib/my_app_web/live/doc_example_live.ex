defmodule MyAppWeb.DocExampleLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
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
    """
  end

  def mount(_params, _session, socket) do
    form =
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
      |> AshPhoenix.Form.add_form([:items])
      |> to_form()

    {:ok, assign(socket, form: form)}
  end

  # In order to use the `add_form` and `remove_form` helpers, you
  # need to make sure that you are validating the form on change
  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
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

  def handle_event("add_form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.add_form(socket.assigns.form, path)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("remove_form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.remove_form(socket.assigns.form, path)
    {:noreply, assign(socket, form: form)}
  end
end
