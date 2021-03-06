defmodule Prestige.Middleware.Retry do
  @moduledoc """
  Tesla plug that will retry the http request when an error or 503 status code is returned.
  Will retry for a configurable amount of time

  Options:

      * `:max_retries` - Override amount of retry attempts (default: 5)
      * `:delay` - Delay between requests in milliseconds (default: 1000ms)

  ## Examples

      `plug(Prestige.Middleware.Retry, delay: 100, max_retries: 5)`

  """
  @behaviour Tesla.Middleware

  @defaults [
    delay: 1000,
    max_retries: 5
  ]

  def call(env, next, opts) do
    opts = opts || []
    delay = Keyword.get(opts, :delay, @defaults[:delay])
    max_retries = Keyword.get(opts, :max_retries, @defaults[:max_retries])

    retry(env, next, delay, max_retries)
  end

  defp retry(env, next, _delay, retries) when retries <= 1 do
    Tesla.run(env, next)
  end

  defp retry(env, next, delay, retries) do
    case Tesla.run(env, next) do
      {:ok, %Tesla.Env{status: 503}} ->
        sleep_and_retry(env, next, delay, retries)

      {:ok, env} ->
        {:ok, env}

      {:error, _reason} ->
        sleep_and_retry(env, next, delay, retries)
    end
  end

  defp sleep_and_retry(env, next, delay, retries) do
    :timer.sleep(delay)
    retry(env, next, delay, retries - 1)
  end
end
