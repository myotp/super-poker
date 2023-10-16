defmodule SuperPoker.IrcDataset.DumpIrcDataset do
  # DB Ecto模块
  alias SuperPoker.IrcDataset.IrcGame
  alias SuperPoker.IrcDataset.IrcTable
  alias SuperPoker.IrcDataset.IrcPlayerActions

  # 纯函数的模块
  alias SuperPoker.IrcDataset.GamePlayers
  alias SuperPoker.IrcDataset.PlayerActions
  alias SuperPoker.IrcDataset.Table

  @dst_folder "/Users/jiaw/dev/poker-irc-dataset/output/"
  @source_irc_tgz_file "/Users/jiaw/dev/poker-irc-dataset/IRCdata.tgz"

  def run(file \\ @source_irc_tgz_file) do
    dir = Path.dirname(file)
    extract_file(file, dir)
    data_files_folder = Path.join(dir, "IRCdata")
    extract_data_files(data_files_folder)
    dump_games_to_db()
    # dump_player_actions_to_db()
    dump_tables_to_db()
  end

  def extract_data_files(folder) do
    Path.wildcard("#{folder}/holdem?.*.tgz")
    |> Enum.each(fn filename ->
      IO.puts("#{timestamp()} Extracting #{filename}")
      extract_file(filename, @dst_folder)
    end)
  end

  def extract_file(filename, to_folder) do
    :erl_tar.extract(~c'#{filename}', [:compressed, {:cwd, ~c'#{to_folder}/'}])
  end

  def dump_player_actions_to_db() do
    disable_ecto_logs()

    Path.wildcard("#{@dst_folder}/holdem3/*/pdb/pdb.*")
    |> Stream.map(fn filename ->
      IO.puts("#{timestamp()} #{filename}")
      File.read!(filename)
    end)
    |> Stream.map(fn content -> String.split(content, "\n", trim: true) end)
    |> Stream.map(fn lines ->
      lines
      |> Enum.map(fn line -> PlayerActions.parse(line) end)
      |> Enum.reject(&is_nil/1)
    end)
    |> Stream.concat()
    |> Stream.each(fn player_actions ->
      case IrcPlayerActions.save_player_actions(player_actions) do
        {:ok, _} ->
          :ok

        {:error, _} ->
          IO.puts("ERROR: player_action.game_id")
      end
    end)
    |> Stream.run()
  end

  def dump_games_to_db() do
    disable_ecto_logs()

    Path.wildcard("#{@dst_folder}/holdem3/*/hroster")
    |> Stream.map(fn filename ->
      IO.puts("#{timestamp()} #{filename}")
      File.read!(filename)
    end)
    |> Stream.map(fn content -> String.split(content, "\n", trim: true) end)
    |> Stream.map(fn lines ->
      lines
      |> Enum.map(fn line -> GamePlayers.parse(line) end)
      |> Enum.reject(&is_nil/1)
    end)
    |> Stream.concat()
    |> Stream.each(fn game_players ->
      case IrcGame.save_game_players(game_players) do
        {:ok, _} ->
          :ok

        {:error, _} ->
          IO.puts("ERROR: #{game_players.game_id}")
      end
    end)
    |> Stream.run()
  end

  def dump_tables_to_db() do
    disable_ecto_logs()

    Path.wildcard("#{@dst_folder}/holdem3/*/hdb")
    |> Stream.map(fn filename ->
      IO.puts("#{timestamp()} #{filename}")
      File.read!(filename)
    end)
    |> Stream.map(fn content -> String.split(content, "\n", trim: true) end)
    |> Stream.map(fn lines ->
      lines
      |> Enum.map(fn line -> Table.parse(line) end)
      |> Enum.reject(&is_nil/1)
    end)
    |> Stream.concat()
    |> Stream.each(fn table_pots_and_community_cards ->
      case IrcTable.save_table(table_pots_and_community_cards) do
        {:ok, _} ->
          :ok

        {:error, _} ->
          IO.puts("ERROR: table_pots_and_community_cards.game_id")
      end
    end)
    |> Stream.run()
  end

  defp disable_ecto_logs() do
    Logger.configure(level: :warning)
  end

  defp timestamp() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_string()
  end
end
