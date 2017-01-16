%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 计数器
%%%
%%% Created : 17. 十二月 2016 下午1:15
%%%-------------------------------------------------------------------
-module(counter_can).

-include("erl_pub.hrl").

-export([get/2, set/1]).

get(Key, MaxNum) ->
    case erlang:get(Key) of
        undefined -> ?true;
        Counter ->
            if
                MaxNum >= Counter -> ?true;
                true -> ?false
            end
    end.

set(Key) ->
    case erlang:get(Key) of
        undefined -> erlang:put(Key, 1);
        Counter -> erlang:put(Key, Counter + 1)
    end.