%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 16. 四月 2016 上午11:05
%%%-------------------------------------------------------------------
-module(erl_list).

-export([move/4]).

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


