%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 27. 四月 2016 上午11:35
%%%-------------------------------------------------------------------

-define(false, false).
-define(true, true).

-define(FALSE, 0).
-define(TRUE, 1).

-define(integer, integer).
-define(list, list).
-define(binary, binary).


-define(put_new(K,V), erlang:put(K,V)). %初始化进程字典，和erlang:put/2区分 开