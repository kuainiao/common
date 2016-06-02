%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 11. 五月 2016 下午12:56
%%%-------------------------------------------------------------------
-module(erl_string).

-export([json_encode/1, json_decode/1, uuid/0]).

%% 由于json解析模块未定，所以应用层需要一个总入口, 方便后面修改接口
%%[{k,v}, {k, [[{k,v},{k,v}], [{k,v}]]}]
json_encode(List) ->
    Fun =
        fun({K, V}) ->
            if
                is_tuple(V) -> {K, {obj, [V]}};
                is_list(V) -> {K, [{obj, I} || I <- V]};
                true -> {K, V}
            end
        end,
    rfc4627:encode({obj, lists:map(Fun, List)}).

json_decode(String) ->
    {ok, {obj, EList}, []} = rfc4627:decode(String),
    EList.


uuid() ->
    Pid = self(),
    Ref = erlang:make_ref(),
    {MegaSecs, Secs, MicroSecs} = os:timestamp(),
    Timers = MegaSecs * 1000000000000 + Secs * 1000000 + MicroSecs,
    erl_md5:md5_to_str(term_to_binary({Pid, Ref, Timers})).