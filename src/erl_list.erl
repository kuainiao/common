%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 16. 四月 2016 上午11:05
%%%-------------------------------------------------------------------
-module(erl_list).

-export([
    lists_spawn/2,
    diff/3,
    diff_kv/3,
    foldl/3,
    map_break/2
]).


lists_spawn(Fun, Lists) ->
    Ref = erlang:make_ref(),
    Pid = self(),
    [
        receive
            {Ref, Res} -> Res;
            _ -> ok
        end || _ <-
        [spawn(
            fun() ->
                Res = Fun(I),
                Pid ! {Ref, Res}
            end) || I <- Lists]
    ].



diff([], _Ids, DelAcc) -> DelAcc;
diff([OldId | OldIds], Ids, DelAcc) ->
    case lists:member(OldId, Ids) of
        true ->
            diff(OldIds, Ids, DelAcc);
        false ->
            diff(OldIds, Ids, [OldId | DelAcc])
    end.


diff_kv([], _Channels, Acc) -> Acc;
diff_kv([K | OldChannels], Channels, Acc) ->
    case lists:keymember(K, 2, Channels) of
        true ->
            diff_kv(OldChannels, Channels, Acc);
        false ->
            diff_kv(OldChannels, Channels, [K | Acc])
    end.


foldl(Fun, List1, List2) ->
    foldl(Fun, List1, List2, []).

foldl(_Fun, [], _List2, Acc) -> lists:reverse(Acc);
foldl(Fun, [H1 | List1], [H2 | List2], Acc) ->
    HAcc = Fun(H1, H2),
    foldl(Fun, List1, List2, [HAcc | Acc]).


map_break(_Fun, []) -> false;
map_break(Fun, [H | R]) ->
    case Fun(H) of
        false -> map_break(Fun, R);
        Ret -> Ret
    end.