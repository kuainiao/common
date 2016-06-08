%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午2:51
%%%-------------------------------------------------------------------
-module(erl_can).

-include("erl_pub.hrl").

-export([can/1,
    %% @doc 类型验证,类型转换
    is_type/2, is_t2t/3,

    %% @doc 字符类验证
    check_illegal_chars/1
]).

can(FunList) ->
    can(FunList, []).

can([], Arg) -> {ok, lists:reverse(Arg)};
can([Fun | FunList], Arg) ->
    case Fun() of
        {error, Err} -> {error, Err};
        ok -> can(FunList, [[] | Arg]);
        {ok, Data} -> can(FunList, [Data | Arg])
    end.

is_t2t(Data, TypeFrom, TypeTo) ->
    try t2t(Data, TypeFrom, TypeTo) of
        error -> ?return_error(?ERR_CONVERT_TYPE_FAIL);
        NewData -> {ok, NewData}
    catch
        _C:_W ->
            ?return_error(?ERR_CONVERT_TYPE_FAIL)
    end.

t2t(Data, list, integer) ->
    case string:to_integer(Data) of
        {Int, []} -> Int;
        _ -> error
    end.


is_type(Type, Data) ->
    case check_type(Type, Data) of
        false -> ?return_error(?ERR_TYPE_ERROR);
        true -> ok
    end.

check_type(list, L) -> erlang:is_list(L);
check_type(binary, Bin) -> erlang:is_binary(Bin);
check_type(integer, Int) -> erlang:is_integer(Int).


-define(ILLEGAL_CHARACTER, [<<"\'">>, <<"`">>, <<"\\">>]).
check_illegal_chars(Binary) ->
    FunAll = fun(Character) ->
        case binary:match(Binary, Character) of
            nomatch -> true;
            _ -> false
        end
             end,
    case lists:all(FunAll, ?ILLEGAL_CHARACTER) of
        true -> {ok, Binary};
        false -> ?return_error(?ERR_CHARS_VERIFY_FAIL)
    end.
