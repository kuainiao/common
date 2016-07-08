%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc
%%%
%%% Created : 08. 七月 2016 上午11:54
%%%-------------------------------------------------------------------
-module(erl_bif).

-export([ceil/1, floor/1]).


%% 正整数,向上取整
ceil(N) ->
    T = trunc(N),
    case N == T of
        true -> T;
        false -> 1 + T
    end.
%% 正整数,向下取整
floor(X) ->
    T = trunc(X),
    case (X < T) of
        true -> T - 1;
        _ -> T
    end.
