%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 17. 十二月 2016 下午1:28
%%%-------------------------------------------------------------------
-module(page_can).

-include("erl_pub.hrl").

-export([
    size/3,
    page_index/3
]).

size(Page, PageSize, MaxPage) ->
    case erlang:is_integer(Page) of
        true ->
            if
                Page =< 0 -> ?return_err(?ERR_ARG_ERROR);
                Page > MaxPage -> ?return_err(?ERR_PAGE_MAX_SIZE);
                true ->
                    SIndex = (Page - 1) * PageSize + 1,
                    {SIndex, PageSize}
            end;
        _ ->
            ?return_err(?ERR_ARG_ERROR)
    end.

page_index(Page, PageSize, MaxPage) ->
    case erlang:is_integer(PageSize) of
        true ->
            if
                Page =< 0 -> ?return_err(?ERR_ARG_ERROR);
                Page > MaxPage -> ?return_err(?ERR_ARG_ERROR);
                true ->
                    SIndex = (Page - 1) * PageSize,
                    EIndex = Page * PageSize - 1,
                    {SIndex, EIndex}
            end;
        _ ->
            ?return_err(?ERR_ARG_ERROR)
    end.