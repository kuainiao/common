%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:47
%%%-------------------------------------------------------------------
-module(erl_time).

-export([now/0, sec_to_localtime/1]).

now() ->
    os:system_time(seconds).

sec_to_localtime(Times) ->
    MSec = (Times + 8 * 3600) div 1000000,
    Sec = Times - MSec * 1000000,
    calendar:now_to_datetime({MSec, Sec, 0}).