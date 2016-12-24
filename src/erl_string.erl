%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 11. 五月 2016 下午12:56
%%%-------------------------------------------------------------------
-module(erl_string).

-export([json_encode/1, json_decode/1, uuid/0, uuid_int/0]).

-export([re_url/1]).

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
    erl_hash:md5_to_str(term_to_binary({Pid, Ref, Timers})).

uuid_int() ->
    Pid = self(),
    Ref = erlang:make_ref(),
    {MegaSecs, Secs, MicroSecs} = os:timestamp(),
    Timers = MegaSecs * 1000000000000 + Secs * 1000000 + MicroSecs,
    erlang:md5(term_to_binary({Pid, Ref, Timers})).

re_url(Binary) ->
    B1 = binary:replace(Binary, <<" ">>, <<"">>, [global]),
    [B2, _] = cpn_mask_word:checkRes(B1, <<"www\.[a-zA-Z0-9\-_]+\."/utf8>>),
    hd(cpn_mask_word:checkRes(B2, <<"\.[a-zA-Z0-9\-_]+\.(com|cn|net|xin|ltd|store|vip|cc|game|mom|lol|work|pub|club|club|xyz|top|ren|bid|loan|red|biz|mobi|me|win|link|wang|date|party|site|online|tech|website|space|live|studio|press|news|video|click|trade|science|wiki|design|pics|photo|help|gitf|rocks|org|band|market|sotfware|social|lawyer|engineer|gov.cn|name|info|tv|asia|co|so|中国|公司|网络)"/utf8>>)).