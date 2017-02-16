%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 10. 二月 2017 上午11:37
%%%-------------------------------------------------------------------


-define(new_ets(TabName, Pos), ets:new(TabName, [public, named_table, {keypos, Pos}, {read_concurrency, true}])).