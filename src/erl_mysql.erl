%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 16. 五月 2016 下午5:23
%%%-------------------------------------------------------------------
-module(erl_mysql).

-include("../../global/include/global_pub.hrl").

-export([start/0, illegal_character/1, execute/1, execute/2]).

-export([ea/1, ed/1, es/1, el/1, eg/1]).
-export([call_ea/2, call_ed/3, call_es/2, call_el/3, call_eg/2]).
-export([cast_ea/2, cast_ed/3, cast_es/2, cast_el/3, cast_eg/2]).

start() ->
    emysql:start().


-define(ILLEGAL_CHARACTER, [<<"\'">>, <<"`">>, <<"'">>, <<"\\">>]).
illegal_character(K) -> illegal_character(K, ?ILLEGAL_CHARACTER).

illegal_character(_K, []) -> true;
illegal_character(K, [Char | Chars]) ->
    case binary:match(K, Char) of
        nomatch -> illegal_character(K, Chars);
        _ -> false
    end.


execute(SQL) ->
    execute(?pool_gm, SQL).

ea(SQL) -> execute(?pool_account, SQL).
ed(SQL) -> execute(?pool_dynamic, SQL).
es(SQL) -> execute(?pool_static, SQL).
el(SQL) -> execute(?pool_log, SQL).
eg(SQL) -> execute(?pool_gm, SQL).

call_ea(App, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:call(Node, ?rpc_func, ea, [Sql]).

call_ed(App, Uin, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:call(Node, ?rpc_func, ed, [Uin, Sql]).

call_es(App, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:call(Node, ?rpc_func, es, [Sql]).

call_el(App, Uin, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:call(Node, ?rpc_func, el, [Uin, Sql]).

call_eg(App, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:call(Node, ?rpc_func, eg, [Sql]).


cast_ea(App, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:cast(Node, ?rpc_func, ea, [Sql]).

cast_ed(App, Uin, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:cast(Node, ?rpc_func, ed, [Uin, Sql]).

cast_es(App, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:cast(Node, ?rpc_func, es, [Sql]).

cast_el(App, Uin, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:cast(Node, ?rpc_func, el, [Uin, Sql]).

cast_eg(App, Sql) ->
    {ok, Node} = application:get_env(App, ?db_node),
    rpc:cast(Node, ?rpc_func, eg, [Sql]).


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
    try emysql:execute(Pool, Sql, 30000) of
        {result_packet, _SeqNum, _FieldList, Rows, _Extra} ->
            Rows;
        {ok_packet, _SeqNum, _AffectedRows, InsertId, _Status, _WarningCount, _Msg} ->
            InsertId;
        {error_packet, _SeqNum, _Code, _Status, _Msg} ->
            ?ERROR("emysql:execute error:~p~nPool:~p...SQL:~p~n", [{error_packet, _SeqNum, _Code, _Status, _Msg}, Pool, Sql]),
            ?return_err('ERR_EXEC_SQL_ERR');
        Packets ->
            case catch ret(Packets, []) of
                {throw, 'ERR_EXEC_SQL_ERR'} ->
                    ?ERROR("emysql:execute error POOL:~p...SQL:~ts~n", [Pool, Sql]),
                    {error, 'ERR_EXEC_SQL_ERR'};
                Ret -> Ret
            end
    catch
        _E1:_E2 ->
            ?ERROR("emysql:execute crash:catch:~p~nwhy:~p~nPool:~p...SQL:~p~n", [_E1, _E2, Pool, Sql]),
            timer:sleep(3000),
            execute(Pool, Num + 1, Sql)
    end.

ret([], Acc) -> lists:reverse(Acc);
ret([{result_packet, _SeqNum, _FieldList, Rows, _Extra} | R], Acc) -> ret(R, [Rows | Acc]);
ret([{ok_packet, _SeqNum, _AffectedRows, InsertId, _Status, _WarningCount, _Msg} | R], Acc) -> ret(R, [InsertId | Acc]);
ret([{error_packet, _SeqNum, _Code, _Status, _Msg} | _R], _Acc) ->
    ?ERROR("emysql:execute error:~p~n SQL_FAIL:~p~nSQL_SUCCESS::~p~n", [{error_packet, _SeqNum, _Code, _Status, _Msg}, _R, _Acc]),
    ?return_err('ERR_EXEC_SQL_ERR').
