%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 15. 三月 2016 下午3:07
%%%-------------------------------------------------------------------

-define(assertEqual(Expect, Expr),
    if
        Expect =:= Expect ->
            ok;
        true -> erlang:error({error, no_match})
    end).

-define(assertEqual(Expect, Expr, Err),
        if
            Expect =:= Expect ->
                ok;
            true -> erlang:error(Err)
        end).