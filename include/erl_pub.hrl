%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 27. 四月 2016 下午2:05
%%%-------------------------------------------------------------------

-include("erl_lager_log.hrl").
-include("erl_common.hrl").
-include("erl_err_code.hrl").

-define(return_err(Err), erlang:throw({throw, Err})).

%%-define(assert(Fun, Ret, Err), if Fun =:= Ret -> ok; true -> erlang:throw({throw, Err}) end).

-define(check(Fun, Msg, Arg),
    case (Fun) of
        true -> true;
        false ->
            io:format(Msg, Arg),
            erlang:throw({throw, false})
    end).

-define(check(Fun, Msg),
    case (Fun) of
        true -> true;
        false ->
            io:format(Msg),
            erlang:throw({throw, false})
    end).


-ifdef(windows).

-define(encode(Data), list_to_binary(rfc4627:encode(Data))).
-define(decode(Data),
    case rfc4627:decode(Data) of
        {ok, {obj, Obj}, []} ->
            Obj;
        {ok, Obj, []} ->
            Obj
    end).


-define(proto_decode(Data),
    case rfc4627:decode(Data) of
        {ok, {obj, Obj}, []} ->
            Obj;
        {ok, Obj, []} ->
            Obj
    end).


-else.

-define(encode(Data), jiffy:encode(Data)).
-define(decode(Data),
    case jiffy:decode(Data) of
        {Decode} -> Decode;
        Decode -> Decode
    end).

-define(proto_decode(Data), jiffy:decode(Data)).

-endif.


-define(mysql_account_pool, account_pool).
-define(mysql_dynamic_pool, dynamic_pool).
-define(mysql_static_pool, static_pool).
-define(mysql_log_pool, log_pool).
-define(mysql_gm_tool, gm_pool).