%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc
%%%
%%% Created : 13. 七月 2016 上午11:26
%%%-------------------------------------------------------------------
-module(erl_httpc).

-export([get/2, post/4, request/4]).

get(Url, Head) ->
    case httpc:request(get, {Url, Head}, [{timeout, 5000}], []) of
        {ok, {{_, 200, "OK"}, _Head, Response}} ->
            {ok, Response};
        _Err ->
            _Err
    end.

post(Url, Head, ContentType, Body) ->
    case httpc:request(post, {Url, Head, ContentType, Body}, [{timeout, 5000}], []) of
        {ok, {{_, 200, "OK"}, _Head, Response}} ->
            {ok, Response};
        _Err ->
            _Err
    end.

request(_Method, _Request, _HTTPOptions, _Options, 3) -> {error, timeout};
request(Method, Request, HTTPOptions, Options, N) ->
    case request(Method, Request, HTTPOptions, Options) of
        {ok, Body} -> {ok, Body};
        _Err ->
            io:format("httpc_get error:~p~n", [_Err]),
            if
                N =:= 0 -> timer:sleep(1000);
                N =:= 1 -> timer:sleep(3000);
                N =:= 2 -> timer:sleep(5000)
            end,
            request(Method, Request, HTTPOptions, Options, N + 1)
    end.

request(Method, Request, HTTPOptions, Options) ->
    case request(Method, Request, HTTPOptions, Options, 0) of
        {ok, {{_, 200, "OK"}, _Head, Response}} ->
            {ok, Response};
        _Err ->
            _Err
    end.
