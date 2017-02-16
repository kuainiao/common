%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 27. 四月 2016 下午2:05
%%%-------------------------------------------------------------------

-include("erl_ets.hrl").
-include("erl_keywords.hrl").
-include("erl_lager_log.hrl").
-include("erl_verify.hrl").

-define(put_new(K, V), erlang:put(K, V)). %初始化进程字典，和erlang:put/2区分 开

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

