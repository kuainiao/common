%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:47
%%%-------------------------------------------------------------------
-module(erl_time).

-export([now/0, times/0, times/1, sec_to_localtime/1, zero_times/0]).

now() ->
%%    os:system_time(seconds).
    times().

times() ->
    {MegaSec, Sec, _MilliSec} = os:timestamp(),
    MegaSec * 1000000 + Sec.

times(milli_seconds) ->
    {MegaSec, Sec, _MilliSec} = os:timestamp(),
    MegaSec * 1000000000 + Sec * 1000 + (_MilliSec div 1000).

sec_to_localtime(Times) ->
    MSec = Times div 1000000,
    Sec = Times - MSec * 1000000,
    calendar:now_to_local_time({MSec, Sec, 0}).


zero_times() ->
    Times = times(),
    case erlang:time() of
        {0, 0, 0} ->
            Times;
        {H, M, S} ->
            Times - (3600 * H + 60 * M + S)
    end.