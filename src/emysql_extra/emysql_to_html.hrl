to_module(Mod) ->
    {Y, M, D} = erlang:date(),
    {H, Mi, S} = erlang:time(),
    Time = <<(integer_to_binary(Y))/binary, "-", (integer_to_binary(M))/binary, "-", (integer_to_binary(D))/binary,
        " ", (integer_to_binary(H))/binary, ":", (integer_to_binary(Mi))/binary, ":", (integer_to_binary(S))/binary>>,

    <<"%%%-------------------------------------------------------------------
%%% @doc 自动生成，请不要手动编辑
%%%
%%% Created :"/utf8, Time/binary, "
%%%-------------------------------------------------------------------
-module(", Mod/binary, ").

-compile(export_all).

-include(\"mysql_tab_record.hrl\").

">>.

to_record(Tab, KvList) ->
    Foldl =
        fun({K, Default, Comment}, {Acc, {Index, Totle}}) ->
            NewK = iolist_to_binary(erl_io:format("~-20s", [K])),
            NewComment = case Comment of
                             <<>> -> <<"\n">>;
                             _ -> <<" % ", Comment/binary, "\n">>
                         end,
            if
                Index =:= Totle ->
                    {
                        <<Acc/binary, "    ", NewK/binary, " = <<\"", Default/binary, "\">>", NewComment/binary>>,
                        {Index + 1, Totle}
                    };
                true ->
                    {
                        <<Acc/binary, "    ", NewK/binary, " = <<\"", Default/binary, "\">>,", NewComment/binary>>,
                        {Index + 1, Totle}
                    }
            end
        end,
    {NewRecord, _} = lists:foldl(Foldl, {<<>>, {1, length(KvList)}}, KvList),

    <<"-record(", Tab/binary, ", {
", NewRecord/binary, "
}).


">>.

to_field(Fields) ->
    Fun =
        fun(I) ->
            Line = iolist_to_binary(binary:split(iolist_to_binary(io_lib:format("~p", [I])), <<"\n">>, [global, trim_all])),
            <<"%% ", Line/binary, "\n">>
        end,
    lists:map(Fun, Fields).

to_insert(Tab, KvList) ->
    Fields = fun_arg(KvList),

    Foldl =
        fun({K, _Default, _Comment}, {FunAcc, Values}) ->

            Variate = list_to_binary(string:to_upper(binary_to_list(K))),
            Fun = <<"            ", Variate/binary, " = Fun(Record#", Tab/binary, ".", K/binary, "),\n">>,
            NewV = <<"                \",", Variate/binary, "/binary, \"">>,
            Values1 = if
                          Values == <<>> -> NewV;
                          true -> <<Values/binary, ",\n", NewV/binary>>
                      end,
            {<<FunAcc/binary, Fun/binary>>, Values1}
        end,
    {FunArg, NewValues} = lists:foldl(Foldl, {<<>>, <<>>}, KvList),

    <<"


insert(Record) ->
    case insert(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

insert(Record, sql) ->
    case check_fields(Record) of
        {ok, _FieldData} ->
            Fun =
                fun(Key) ->
                    if
                        is_integer(Key) -> integer_to_binary(Key);
                        Key =:= <<\"''\">> -> <<\"''\">>;
                        true -> <<\"'\", Key/binary, \"'\">>
                    end
                end,
", FunArg/binary, "
            <<\"insert into `", Tab/binary, "` (", Fields/binary, ") value (
", NewValues/binary, "
                );\">>;
        _Err ->
            _Err
    end.


">>.

to_delete(Tab, []) ->
    <<"delete(_Record) -> io:format(\"table:", Tab/binary, "...no pri_key~n\"), {error, <<\"no_pri_key\">>}.

">>;
to_delete(Tab, PRIList) ->
    Foldl = fun({Field, Default}, {Fun, Where}) ->
        Can = fun_can(Tab, Field),
        SqlWhere = fun_where(Tab, Field, Default),
        Fun2 = if
                   Fun == <<>> -> Can;
                   true -> <<Fun/binary, ",", Can/binary>>
               end,
        Where2 = if
                     Where == <<>> -> SqlWhere;
                     true -> <<Where/binary, " AND ", SqlWhere/binary>>
                 end,
        {Fun2, Where2}
            end,
    {NewFun, NewWhere} = lists:foldl(Foldl, {<<>>, <<>>}, PRIList),

    <<"delete(Record) ->
    case delete(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

delete(Record, sql) ->
    case erl_can:can([", NewFun/binary, "
    ]) of
        {ok, _} ->
            <<\"delete from ", Tab/binary, " where
            ", NewWhere/binary, ";\">>;
        _Err ->
            _Err
    end.

">>.

to_update(Tab, [], _) ->
    <<"update(_Record) -> io:format(\"table:", Tab/binary, "...no pri_key~n\"), {error, <<\"no_pri_key\">>}.

">>;

to_update(Tab, _, []) ->
    <<"update(_Record) -> io:format(\"table:", Tab/binary, "...all pri_key~n\"), {error, <<\"all_pri_key\">>}.

">>;

to_update(Tab, PRIList, _OtherList) ->
    Foldl =
        fun({Field, Default}, Where) ->
            SqlWhere = fun_where(Tab, Field, Default),
            if
                Where == <<>> -> SqlWhere;
                true -> <<Where/binary, " AND ", SqlWhere/binary>>
            end
        end,
    NewWhere = lists:foldl(Foldl, <<>>, PRIList),
    Len = length(PRIList),
    Filter = list_to_binary(string:join(["_" || _I <- lists:seq(1, Len)], ", ")),

    <<"update(Record) ->
    case update(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

update(Record, sql) ->
    case check_fields(Record) of
        {ok, [", Filter/binary, " | FieldData]} ->
            {SetAcc, _} = lists:foldl(
                fun({K, Default}, {Acc, Num}) ->
                    if
                        Default =:= element(Num, #", Tab/binary, "{}) ->
                            {Acc, Num + 1};
                        true ->
                            {<<Acc/binary, K/binary, \" = \", Default/binary>>, Num + 1}
                    end
                end,
                {<<>>, ", (integer_to_binary(Len))/binary, "},
                FieldData),
            <<\"update ", Tab/binary, " set \", SetAcc/binary, \" where
   ", NewWhere/binary, ";\">>;
        _Err ->
            _Err
    end.

">>.


to_lookup(Tab, _, [], _) ->
    <<"lookup(_Record) -> io:format(\"table:", Tab/binary, "...no pri_key~n\"), {error, <<\"no_pri_key\">>}.

">>;

to_lookup(Tab, _, _, []) ->
    <<"lookup(_Record) -> io:format(\"table:", Tab/binary, "...all pri_key~n\"), {error, <<\"all_pri_key\">>}.

">>;

to_lookup(Tab, KvList, PRIList, _OtherList) ->
    Foldl =
        fun({Field, Default}, {Fun, Where}) ->
            Can = fun_can(Tab, Field),
            SqlWhere = fun_where(Tab, Field, Default),
            Fun2 = if
                       Fun == <<>> -> Can;
                       true -> <<Fun/binary, ",", Can/binary>>
                   end,
            Where2 = if
                         Where == <<>> -> SqlWhere;
                         true -> <<Where/binary, " AND ", SqlWhere/binary>>
                     end,
            {Fun2, Where2}
        end,
    {NewFun, NewWhere} = lists:foldl(Foldl, {<<>>, <<>>}, PRIList),

    NewFields = fun_arg(KvList),
    Data = list_to_binary(string:join([string:to_upper(binary_to_list(K)) || {K, _D, _C} <- KvList], ", ")),
    RecordData = list_to_binary(string:join([binary_to_list(K) ++ " = " ++ string:to_upper(binary_to_list(K)) || {K, _D, _C} <- KvList], ", ")),

    <<"lookup(Record) ->
    case lookup(Record, sql) of
        {error, _Err} -> {error, _Err};
        Sql ->
            [[", Data/binary, "]] = erl_mysql:execute(Sql),
            Record#", Tab/binary, "{", RecordData/binary, "}
    end.

lookup(Record, sql) ->
    case erl_can:can([", NewFun/binary, "
    ]) of
        {ok, _} ->
            <<\"select ", NewFields/binary, " from ", Tab/binary, "
            where
            ", NewWhere/binary, "
            ;\">>;

        _Err ->
            _Err
    end.

">>.


to_check_fields(Tab, KvList) ->
    Can = lists:foldl(
        fun({K, _V, _Comment}, Fields) ->
            if
                Fields =:= <<>> ->
                    <<"        fun() -> validate(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>;
                true ->
                    <<Fields/binary, ",\n        fun() -> validate(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>
            end
        end, <<>>, KvList),

    <<"check_fields(Record) ->
case erl_can:can([
", Can/binary, "
    ]) of
        {ok, FieldData} ->
            {ok, FieldData};
        ErrCode -> ErrCode
    end.


">>.

to_validate() ->
    <<"validate(Table, Field, Value) ->
    case validate(Field, Value) of
        false ->
            io:format(\"error tab:~p record:~p val:~p validate_fail~n\", [Table, Field, Value]),
            {error, validate_fail};
        true ->
            {ok, {Field, Value}}
    end.


">>.

to_validate(FieldsRecord) ->
    Fun =
        fun({K, DataType, TypeSize, IsNull, Default}) ->
            KArg = list_to_binary(string:to_upper(binary_to_list(K))),
            CheckNull = if
                            IsNull =:= <<"NO">> -> <<"(", KArg/binary, "=/= ", Default/binary, ")">>;
                            true -> <<"">>
                        end,
            CheckType = if
                            DataType =:= int ->
                                <<"( is_integer(", KArg/binary, ") andalso ", KArg/binary, " >= -2147483648 andalso ", KArg/binary, " =< 2147483648 ) ">>;
                            TypeSize =:= null ->
                                <<"( is_binary(", KArg/binary, ") )">>;
                            DataType =:= binary ->
                                <<"( is_binary(", KArg/binary, ") andalso byte_size(", KArg/binary, ") =< ", TypeSize/binary, ")">>
                        end,
            if
                CheckNull =:= <<"">> ->
                    <<"validate('", K/binary, "', ", KArg/binary, ") -> ", CheckType/binary, " andalso erl_mysql:illegal_character(", KArg/binary, ");\n">>;
                true ->
                    <<"validate('", K/binary, "', ", KArg/binary, ") -> ", CheckNull/binary, " orelse ", CheckType/binary, " andalso erl_mysql:illegal_character(", KArg/binary, ");\n">>
            end
        end,
    <<(iolist_to_binary(lists:map(Fun, FieldsRecord)))/binary,
        "validate(_K, _V) ->
    io:format(\"error no field:~p~n\", [[_K, _V]]),
    false.">>.


fun_arg(AccRecord) ->
    lists:foldl(
        fun({K, _Default, _Comment}, Fields) ->
            if
                Fields =:= <<>> -> <<"`", K/binary, "`">>;
                true -> <<Fields/binary, ", `", K/binary, "`">>
            end
        end, <<>>, AccRecord).

fun_can(Tab, Field) ->
    <<"\n        fun() -> validate(", Tab/binary, ", '", Field/binary, "', Record#", Tab/binary, ".", Field/binary, ") end">>.

fun_where(Tab, Field, V) ->
    if
        is_integer(V) ->
            <<Field/binary, " = \",(integer_to_binary(Record#", Tab/binary, ".", Field/binary, "))/binary, \"">>;
        is_binary(V) ->
            <<Field/binary, " = '\",(Record#", Tab/binary, ".", Field/binary, ")/binary, \"'">>
    end.