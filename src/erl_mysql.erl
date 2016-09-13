%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 16. 五月 2016 下午5:23
%%%-------------------------------------------------------------------
-module(erl_mysql).

-include("erl_pub.hrl").

-export([start/0, illegal_character/1, execute/1, execute/2, ea/1, ed/1, es/1, el/1, eg/1]).


start() ->
    emysql:start().


-define(ILLEGAL_CHARACTER, [<<"\'">>, <<"`">>]).
illegal_character(K) -> illegal_character(K, ?ILLEGAL_CHARACTER).

illegal_character(_K, []) -> true;
illegal_character(K, [Char | Chars]) ->
    case binary:match(K, Char) of
        nomatch -> illegal_character(K, Chars);
        _ -> false
    end.


execute(SQL) ->
    execute(?mysql_gm_tool, SQL).

ea(SQL) -> execute(?mysql_account_pool, SQL).
ed(SQL) -> execute(?mysql_dynamic_pool, SQL).
es(SQL) -> execute(?mysql_static_pool, SQL).
el(SQL) -> execute(?mysql_log_pool, SQL).
eg(SQL) -> execute(?mysql_gm_tool, SQL).

execute(Pool, SQL) ->
    case iolist_to_binary(SQL) of
        <<>> -> ok;
        Sql ->
%%            ?WARN("SQL:~ts~n", [SQL]),
            execute(Pool, 0, Sql)
    end.


execute(Pool, 6, Sql) ->
    ?ERROR("sql ex error:pool:~p...sql:~p~n", [Pool, Sql]),
    {error, []};

execute(Pool, Num, Sql) ->
    try emysql:execute(Pool, Sql, 10000) of
        {result_packet, _SeqNum, _FieldList, Rows, _Extra} ->
            Rows;
        {ok_packet, _SeqNum, _AffectedRows, InsertId, _Status, _WarningCount, _msg} ->
            InsertId;
        Packets ->
            Fun = fun({result_packet, _SeqNum, _FieldList, Rows, _Extra}) -> Rows;
                ({ok_packet, _SeqNum, _AffectedRows, InsertId, _Status, _WarningCount, _msg}) -> InsertId;
                ({error_packet, SeqNum, Code, Status, Msg}) ->
                    ?ERROR("emysql:execute error:~p~n POOL:~p...SQL:~ts~n", [{error_packet, SeqNum, Code, Status, Msg}, Pool, Sql]),
                    ?return_err('ERR_EXEC_SQL_ERR')
                  end,
            lists:map(Fun, Packets)
    catch
        _E1:_E2 ->
            ?ERROR("emysql:execute crash:catch:~p~nwhy:~p~nPool:~p...SQL:~p~n", [_E1, _E2, Pool, Sql]),
            timer:sleep(3000),
            execute(Pool, Num + 1, Sql)
    end.

