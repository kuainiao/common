%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:47
%%%-------------------------------------------------------------------
-module(erl_random).

-export([rand/2, random/1, random/2]).


rand(MaxNum, List) ->
    L = random(MaxNum),
    rand_s(L, List, 1).

rand_s(_Num, [], _Index) -> 1;
rand_s(Num, [H | R], Index) ->
    if
        Num =< H -> Index;
        true ->
            rand_s(Num - H, R, Index + 1)
    end.


random(Max) ->
%%    seed(),
    rand:uniform(Max).

random(Min, Max) ->
%%    seed(),
    rand:uniform(Max - Min + 1) + Min - 1.


%%seed() ->
%%    <<A:32, B:32, C:32>> = crypto:strong_rand_bytes(12),
%%    random:seed({A, B, C}).