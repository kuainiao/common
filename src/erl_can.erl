%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:51
%%%-------------------------------------------------------------------
-module(erl_can).

-export([can/1]).

can(FunList) ->
    can(FunList, []).

can([], Arg) -> {ok, lists:reverse(Arg)};
can([Fun | FunList], Arg) ->
    case Fun() of
        {error, Err} -> {error, Err};
        ok -> can(FunList, [[] | Arg]);
        {ok, Data} -> can(FunList, [Data | Arg])
    end.