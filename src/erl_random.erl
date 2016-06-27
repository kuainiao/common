%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:47
%%%-------------------------------------------------------------------
-module(erl_random).

-export([random/1]).

random(Max) ->
    <<A:32, B:32, C:32>> = crypto:strong_rand_bytes(12),
    random:seed({A, B, C}),
    random:uniform(Max).
