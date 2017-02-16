%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 14. 二月 2017 下午5:19
%%%-------------------------------------------------------------------
-module(erl_node).

-include("../../global/include/global_pub.hrl").

-export([node_alive/1]).


node_alive(Node) ->
    case net_kernel:connect_node(Node) of
        true ->
            ok;
        false ->
            ?ERROR("node not alive:~p ~n", [Node]),
            erlang:halt()
    end.