%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc
%%%
%%% Created : 18. 七月 2016 上午9:17
%%%-------------------------------------------------------------------
-module(binary_can).

-include("erl_pub.hrl").

-export([
    illegal/1,          %非法字符
    mask_word/1,        %屏蔽字符
    is_binary/1,
    char2char/3         %特殊符号转义
]).

illegal(Binary) ->
    case erl_mysql:illegal_character(Binary) of
        true ->
            ok;
        false ->
            ?return_err(?ERR_ILLEGAL_CHATS)
    end.

%% @doc 回车换行转义
char2char(Binary, Char1, Char2) ->
    binary:replace(Binary, Char1, Char2, [global]).

mask_word(Binary) ->
    case cpn_mask_word:checkRes(Binary) of
        [_, false] -> ok;
        [_, true] -> ?return_err(?ERR_SENSITIVE_CHARACTER)
    end.


is_binary(<<"">>) -> ?return_err(?ERR_ARG_ERROR);
is_binary(Binary) ->
    case erlang:is_binary(Binary) of
        true -> ok;
        false -> ?return_err(?ERR_ARG_ERROR)
    end.