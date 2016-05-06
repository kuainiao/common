%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:47
%%%-------------------------------------------------------------------
-module(erl_time).

-export([now/0, sec_to_localtime/1, today/0]).

now() ->
    os:system_time(seconds).

sec_to_localtime(Times) ->
    MSec = Times div 1000000,
    Sec = Times - MSec * 1000000,
    calendar:now_to_local_time({MSec, Sec, 0}).


today() ->
    Times = os:system_time(seconds),
    case erlang:time() of
        {0, 0, 0} ->
            Times;
        {H, M, S} ->
            Times - (3600 * H + 60 * M + S)
    end.