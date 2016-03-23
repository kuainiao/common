%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:45
%%%-------------------------------------------------------------------
-module(erl_md5).

-export([md5/1, md5_to_str/1]).

md5(S) ->
    Md5_bin = erlang:md5(S),
    Md5_list = binary_to_list(Md5_bin),
    lists:flatten(list_to_hex(Md5_list)).

list_to_hex(L) ->
    lists:map(fun(X) -> int_to_hex(X) end, L).

int_to_hex(N) when N < 256 ->
    [hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
    $0 + N;

hex(N) when N >= 10, N < 16 ->
    $a + (N - 10).


md5_to_str(Str) ->
    <<M:128/integer>> = erlang:md5(Str),
    int_to_hex(M, 32).

int_to_hex(I, Len) ->
    Hex = string:to_lower(erlang:integer_to_list(I, 16)),
    LenDiff = Len - length(Hex),
    case LenDiff > 0 of
        true -> string:chars($0, LenDiff) ++ Hex;
        false -> Hex
    end.