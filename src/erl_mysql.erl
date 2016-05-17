%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 16. 五月 2016 下午5:23
%%%-------------------------------------------------------------------
-module(erl_mysql).


-export([start/0, illegal_character/1, execute/1]).


start() ->
    emysql:start().


-define(ILLEGAL_CHARACTER, [<<"\'">>, <<"`">>, <<"\\">>]).
illegal_character(K) -> illegal_character(K, ?ILLEGAL_CHARACTER).

illegal_character(_K, []) -> true;
illegal_character(K, [Char | Chars]) ->
    case binary:match(K, Char) of
        nomatch -> illegal_character(K, Chars);
        _ -> false
    end.


execute(SQL) ->
    Sql = iolist_to_binary(SQL),
    io:format("SQL:~ts~n", [Sql]),
    try emysql:execute(platform_pool, Sql, 10000) of
        {result_packet, _, _, Data, _} ->
            Data;
        {ok_packet, _, _, Data, _, _, _} ->
            Data;
        [{result_packet, _, _, Data, _}, _] ->
            Data;
        [{ok_packet, _, _, _, __, _, _} | _] ->
            ok;
        _Error ->
            io:format("emysql:execute error:~p~n SQL:~ts~n", [_Error, Sql]),
            {error, 'ERR_EXEC_SQL_ERR'}
    catch
        _E1:_E2 ->
            io:format("emysql:execute crash:catch:~p~nwhy:~p~nSQL:~p~n", [_E1, _E2, Sql]),
            {error, 'ERR_EXEC_SQL_ERR'}
    end.

