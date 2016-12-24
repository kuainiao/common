%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc
%%%
%%% Created : 18. 七月 2016 上午9:17
%%%-------------------------------------------------------------------
-module(list_can).

-include("erl_pub.hrl").

-export([
    member/3
]).

member(Key, List, ErrCode) ->
    case lists:member(Key, List) of
        true -> ok;
        false -> ?return_err(ErrCode)
    end.