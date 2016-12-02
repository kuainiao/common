%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:47
%%%-------------------------------------------------------------------
-module(erl_time).

-export([now/0, m_now/0, c_ms/0,
    times/0, times/1,
    zero_times/0,
    localtime_to_now/1,
    sec_to_localtime/1,
    time2timer/1,
    times_in_month/1
]).

%% @doc 获取当前服务器时间的时间戳
now() ->
%%    os:system_time(seconds).
    times().

m_now() ->
    {MegaSec, Sec, MilliSec} = os:timestamp(),
    MegaSec * 1000000000 + Sec * 1000 + round(MilliSec / 1000).

c_ms() ->
    {_MegaSec, _Sec, MilliSec} = os:timestamp(),
    round(MilliSec / 1000).

times() ->
    {MegaSec, Sec, _MilliSec} = os:timestamp(),
    MegaSec * 1000000 + Sec.

times(milli_seconds) ->
    {MegaSec, Sec, _MilliSec} = os:timestamp(),
    MegaSec * 1000000000 + Sec * 1000 + (_MilliSec div 1000);

times(micro_second) ->
    {MegaSec, Sec, _MilliSec} = os:timestamp(),
    MegaSec * 1000000000000 + Sec * 1000000 + _MilliSec.

sec_to_localtime(Times) ->
    MSec = Times div 1000000,
    Sec = Times - MSec * 1000000,
    calendar:now_to_local_time({MSec, Sec, 0}).


-define(TIMES_START_DATE, 62167248000). %calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}})+3600*8.
localtime_to_now({Date, Time}) ->
    calendar:datetime_to_gregorian_seconds({Date, Time}) - ?TIMES_START_DATE.

zero_times() ->
    Times = times(),
    case erlang:time() of
        {0, 0, 0} ->
            Times;
        {H, M, S} ->
            Times - (3600 * H + 60 * M + S)
    end.

%2016-07-19 00:00:00
time2timer(Time) ->
    [Y, M, D, H, Mi, S] = binary:split(Time, [<<"-">>, <<" ">>, <<":">>], [global]),
    localtime_to_now({{binary_to_integer(Y), binary_to_integer(M), binary_to_integer(D)}, {binary_to_integer(H), binary_to_integer(Mi), binary_to_integer(S)}}).


times_in_month(Times) ->
    Date = erlang:date(),
    MTimes = localtime_to_now({Date, {0, 0, 0}}),
    if
        Times < MTimes -> false;
        true -> true
    end.
    