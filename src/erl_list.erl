%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 16. 四月 2016 上午11:05
%%%-------------------------------------------------------------------
-module(erl_list).

-export([move/4, lists_spawn/2, diff/3, diff_kv/3, foldl/3]).

%%  @doc 调换顺序
move(0, FromItem, ToItem, List) ->
    FromIndex = index(FromItem, List, 1),
    ToIndex = index(ToItem, List, 1),
    if
        FromIndex =< ToIndex ->
            FirstChunk = lists:sublist(List, 0, FromIndex - 1),
            SecondChunk = lists:sublist(List, FromIndex, ToIndex - 1),
            LastChunk = lists:sublist(List, ToIndex, length(List)),
            lists:merge3(FirstChunk, [FromItem | SecondChunk], [ToItem | LastChunk]);
        true ->
            FirstChunk = lists:sublist(List, 0, ToIndex - 1),
            SecondChunk = lists:sublist(List, ToIndex, FromIndex - 1),
            LastChunk = lists:sublist(List, FromIndex, length(List)),
            lists:merge3(FirstChunk, [ToItem | SecondChunk], [FromItem | LastChunk])
    end;

%% @doc From移动到to，从to开始往后移动一位
move(1, FromItem, ToItem, List) ->
    FromIndex = index(FromItem, List, 1),
    ToIndex = index(ToItem, List, 1),
    if
        FromIndex =< ToIndex ->
            FirstChunk = lists:sublist(List, 0, FromIndex - 1),
            SecondChunk = lists:sublist(List, FromIndex, ToIndex - 1),
            LastChunk = lists:sublist(List, ToIndex, length(List)),
            lists:merge3(FirstChunk, SecondChunk, [ToItem, FromItem | LastChunk]);
        true ->
            FirstChunk = lists:sublist(List, 0, ToIndex - 1),
            SecondChunk = lists:sublist(List, ToIndex, FromIndex - 1),
            LastChunk = lists:sublist(List, FromIndex, length(List)),
            lists:merge3(FirstChunk, [FromItem, ToItem | SecondChunk], LastChunk)
    end.


index(_Item, [], _Num) -> 0;
index(Item, [Item | _List], Num) -> Num;
index(Item, [_I | List], Num) -> index(Item, List, Num + 1).

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
    