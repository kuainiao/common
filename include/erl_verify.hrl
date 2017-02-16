%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 10. 二月 2017 上午11:15
%%%-------------------------------------------------------------------


-define(return_err(Err), erlang:throw({throw, Err})).

-define(assert_equal(Expect, Expr),
    if
        Expect =:= Expect ->
            ok;
        true -> erlang:error({error, no_match})
    end).

-define(assert_equal(Expect, Expr, Err),
    if
        Expect =:= Expect ->
            ok;
        true -> erlang:error(Err)
    end).


%%-define(assert(Fun, Ret, Err), if Fun =:= Ret -> ok; true -> erlang:throw({throw, Err}) end).

-define(check(Fun, Msg, Arg),
    case (Fun) of
        true -> true;
        false ->
            io:format(Msg, Arg),
            erlang:throw({throw, false})
    end).

-define(check(Fun, Msg),
    case (Fun) of
        true -> true;
        false ->
            io:format(Msg),
            erlang:throw({throw, false})
    end).