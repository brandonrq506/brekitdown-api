defmodule BrekitdownWeb.FlopJSON do
  @moduledoc "Renders Flop validation errors as a field => [messages] map."

  def error(%{meta: %Flop.Meta{errors: errors}}) do
    %{errors: flatten_errors(errors)}
  end

  defp flatten_errors(errors) do
    do_flatten_errors(errors, [], %{})
  end

  defp do_flatten_errors(errors, path, acc) when is_list(errors) do
    cond do
      error_messages?(errors) ->
        Map.put(acc, Enum.join(path, "."), Enum.map(errors, &translate_error/1))

      Keyword.keyword?(errors) ->
        Enum.reduce(errors, acc, fn {field, nested_errors}, nested_acc ->
          do_flatten_errors(nested_errors, path ++ [field], nested_acc)
        end)

      true ->
        errors
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {nested_errors, index}, nested_acc ->
          do_flatten_errors(nested_errors, path ++ [index], nested_acc)
        end)
    end
  end

  defp do_flatten_errors(_errors, _path, acc), do: acc

  defp error_messages?([]), do: false

  defp error_messages?(errors) do
    Enum.all?(errors, fn
      {message, opts} when is_binary(message) and is_list(opts) -> true
      _error -> false
    end)
  end

  defp translate_error({message, opts}) do
    Enum.reduce(opts, message, fn {key, value}, translated ->
      String.replace(translated, "%{#{key}}", fn _match -> to_string(value) end)
    end)
  end
end
