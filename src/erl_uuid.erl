%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:48
%%%-------------------------------------------------------------------
-module(erl_uuid).

-export([uuid/0]).

uuid() ->
    Pid = self(),
    Ref = erlang:make_ref(),
    {MegaSecs, Secs, MicroSecs} = os:timestamp(),
    Timers = MegaSecs * 1000000000000 + Secs * 1000000 + MicroSecs,
    erl_md5:md5_to_str(term_to_binary({Pid, Ref, Timers})).