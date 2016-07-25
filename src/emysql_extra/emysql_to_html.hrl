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
        fun({K, _Default, _Comment}, {FunAcc, Values, Can}) ->

            Variate = list_to_binary(string:to_upper(binary_to_list(K))),
            Fun = <<"            ", Variate/binary, " = Fun(Record#", Tab/binary, ".", K/binary, "),\n">>,
            NewV = <<"                \",", Variate/binary, "/binary, \"">>,
            Values1 =
                if
                    Values == <<>> -> NewV;
                    true -> <<Values/binary, ",\n", NewV/binary>>
                end,
            Can1 =
                if
                    Can =:= <<>> ->
                        <<"        fun() -> validate(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>;
                    true ->
                        <<Can/binary, ",\n        fun() -> validate(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>
                end,
            {<<FunAcc/binary, Fun/binary>>, Values1, Can1}
        end,
    {FunArg, NewValues, NewCan} = lists:foldl(Foldl, {<<>>, <<>>, <<>>}, KvList),

    <<"


insert(Record) ->
    case insert(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

insert(Record, sql) ->
     case erl_can:can([
", NewCan/binary, "
    ]) of
        {ok, _FieldData} ->
            Fun =
                fun(Key) ->
                    if
                        is_integer(Key) -> integer_to_binary(Key);
                        Key =:= <<\"''\">> -> <<\"''\">>;
                        Key =:= <<>> -> <<\"''\">>;
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
    Foldl = fun({Field, Default}, {Arg, Fun, Where}) ->
        Variate = list_to_binary(string:to_upper(binary_to_list(Field))),
        Can = fun_can(Tab, Field, Variate),
        SqlWhere = fun_where(Field, Variate, Default),

        Arg2 = if
                   Arg == <<>> -> Variate;
                   true -> <<Arg/binary, ",", Variate/binary>>
               end,
        Fun2 = if
                   Fun == <<>> -> Can;
                   true -> <<Fun/binary, ",", Can/binary>>
               end,
        Where2 = if
                     Where == <<>> -> SqlWhere;
                     true -> <<Where/binary, " AND ", SqlWhere/binary>>
                 end,
        {Arg2, Fun2, Where2}
            end,
    {NewArg, NewFun, NewWhere} = lists:foldl(Foldl, {<<>>, <<>>, <<>>}, PRIList),

    <<"delete(", NewArg/binary, ") ->
    case delete(", NewArg/binary, ", sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

delete(", NewArg/binary, ", sql) ->
    case erl_can:can([", NewFun/binary, "
    ]) of
        {ok, _} ->
            <<\"delete from ", Tab/binary, " where
            ", NewWhere/binary, ";\">>;
        _Err ->
            _Err
    end.

">>.

to_update(Tab, [], _, _) ->
    <<"update(_Record) -> io:format(\"table:", Tab/binary, "...no pri_key~n\"), {error, <<\"no_pri_key\">>}.

">>;

to_update(Tab, _, [], _) ->
    <<"update(_Record) -> io:format(\"table:", Tab/binary, "...all pri_key~n\"), {error, <<\"all_pri_key\">>}.

">>;

to_update(Tab, PRIList, _OtherList, CanKvList) ->
    Foldl =
        fun({Field, Default}, {Pri, Where, Num}) ->
            Variate = list_to_binary(string:to_upper(binary_to_list(Field))),
            SqlWhere = fun_where(Field, Variate, Default),
            NewWhere = if
                           Where == <<>> -> SqlWhere;
                           true -> <<Where/binary, " AND ", SqlWhere/binary>>
                       end,
            NewPri = if
                         Pri =:= <<>> ->
                             <<"{value, {_, ", Variate/binary, "}, FieldData", (integer_to_binary(Num))/binary, "} = lists:keytake(", Field/binary, ", 1, FieldData),">>;
                         true ->
                             <<Pri/binary, "\n            {value, {_, ", Variate/binary, "}, FieldData", (integer_to_binary(Num))/binary, "} = lists:keytake(", Field/binary, ", 1, FieldData", (integer_to_binary(Num - 1))/binary, "),">>
                     end,
            {NewPri, NewWhere, Num + 1}
        end,
    {NewPri, NewWhere, _} = lists:foldl(Foldl, {<<>>, <<>>, 0}, PRIList),
    Len = length(PRIList),

    NewCan = lists:foldl(
        fun({K, _V, _Comment}, Fields) ->
            if
                Fields =:= <<>> ->
                    <<"        fun() -> validate(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>;
                true ->
                    <<Fields/binary, ",\n        fun() -> validate(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>
            end
        end, <<>>, CanKvList),

    <<"update(Record) ->
    case update(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

update(Record, sql) ->
     case erl_can:can([
", NewCan/binary, "
    ]) of
        {ok, FieldData} ->
            ", NewPri/binary, "
            {SetAcc, _} = lists:foldl(
                fun({K, Default}, Acc) ->
                    case to_default(K) of
                        Default -> Acc;
                        _ ->
                            <<Acc/binary, \",\", K/binary, \" = \", Default/binary>>
                    end
                end,
                <<>>,
                FieldData", (integer_to_binary(Len - 1))/binary, "),
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
        fun({Field, Default}, {Arg, Fun, Where}) ->
            Variate = list_to_binary(string:to_upper(binary_to_list(Field))),
            Can = fun_can(Tab, Field, Variate),
            SqlWhere = fun_where(Field, Variate, Default),

            Arg2 = if
                       Arg == <<>> -> Variate;
                       true -> <<Arg/binary, ",", Variate/binary>>
                   end,

            Fun2 = if
                       Fun == <<>> -> Can;
                       true -> <<Fun/binary, ",", Can/binary>>
                   end,
            Where2 = if
                         Where == <<>> -> SqlWhere;
                         true -> <<Where/binary, " AND ", SqlWhere/binary>>
                     end,
            {Arg2, Fun2, Where2}
        end,
    {NewArg, NewFun, NewWhere} = lists:foldl(Foldl, {<<>>, <<>>, <<>>}, PRIList),

    NewFields = fun_arg(KvList),
    Data = list_to_binary(string:join([string:to_upper(binary_to_list(K)) || {K, _D, _C} <- KvList], ", ")),
    RecordData = list_to_binary(string:join([binary_to_list(K) ++ " = " ++ string:to_upper(binary_to_list(K)) || {K, _D, _C} <- KvList], ", ")),

    <<"lookup(", NewArg/binary, ") ->
    case lookup(", NewArg/binary, ", sql) of
        {error, _Err} -> {error, _Err};
        Sql ->
            [[", Data/binary, "]] = erl_mysql:execute(Sql),
            #", Tab/binary, "{", RecordData/binary, "}
    end.

lookup(", NewArg/binary, ", sql) ->
    case erl_can:can([", NewFun/binary, "
    ]) of
        {ok, _} ->
            <<\"select ", NewFields/binary, " from ", Tab/binary, " where
            ", NewWhere/binary, ";\">>;

        _Err ->
            _Err
    end.

">>.




to_select(Tab, KvList) ->
    Fields = fun_arg(KvList),
    Foldl =
        fun({Field, _Default, _Comment}, {AccField, RFCEncode}) ->

            NewAccField =
                if
                    AccField =:= <<>> -> list_to_binary(string:to_upper(binary_to_list(Field)));
                    true -> <<AccField/binary, ", ", (list_to_binary(string:to_upper(binary_to_list(Field))))/binary>>
                end,
            NewRFCEncode =
                if
                    RFCEncode =:= <<>> ->
                        <<"{<<\"", Field/binary, "\">>, ", (list_to_binary(string:to_upper(binary_to_list(Field))))/binary, "}">>;
                    true ->
                        <<RFCEncode/binary, ", ", "{<<\"", Field/binary, "\">>, ", (list_to_binary(string:to_upper(binary_to_list(Field))))/binary, "}">>
                end,
            {NewAccField, NewRFCEncode}
        end,
    {NewField, NewEncode} = lists:foldl(Foldl, {<<>>, <<>>}, KvList),
    <<"select(SelectKvList, StartIndex, SortKey, SortType ) ->
    SIndex = integer_to_binary(StartIndex),
    case select(SelectKvList, SIndex, <<\"30\">>, SortKey, SortType, sql) of
        {error, Err} -> {error, Err};
        Sql ->
            [[[Count]], Ret] = erl_mysql:execute(Sql),
            Fun =
                fun([", NewField/binary, "]) ->
                    {obj, [", NewEncode/binary, "]}
                end,
            {Count, lists:map(Fun, Ret)}
    end.

select(SelectKvList, StartIndex, Len, SortKey, SortType, sql) ->
    SelectArg = lists:foldl(
        fun({Field, Item}, Acc) ->
            case erl_mysql:illegal_character(Item) of
                false -> Acc;
                true ->
                    if
                        Acc =:= <<>> -> <<Field/binary, \"=\", Item/binary>>;
                        true -> <<Acc/binary, \",\", Field/binary, \"=\", Item/binary>>
                    end

            end
        end,
        <<>>,
        SelectKvList),
    OrderBy =
        if
            SortKey == <<\"\">> -> <<>>;
            true ->
                case SortType of
                \"0\" ->
                    <<\" order by \", SortKey/binary, \" \">>;
                \"1\" ->
                    <<\" order by \", SortKey/binary, \" DESC \">>
            end
        end,
    case SelectArg of
        <<>> ->
            <<\"select count(*) from ", Tab/binary, "; select ", Fields/binary, " from ", Tab/binary, " \", OrderBy/binary, \" limit \", StartIndex/binary, \", \", Len/binary, \";\">>;
        _ ->
            <<\"select count(*) from ", Tab/binary, "; select ", Fields/binary, " from ", Tab/binary, " where \", SelectArg/binary, \", " ", \", OrderBy/binary, \" limit \", StartIndex/binary, \", \", Len/binary, \";\">>
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
                            IsNull =:= <<"NO">> -> <<"(", KArg/binary, "=/= <<\"", Default/binary, "\">>)">>;
                            true -> <<"">>
                        end,
            {CheckType, Illegal} =
                if
                    DataType =:= int ->
                        {<<"( is_integer(", KArg/binary, ") andalso ", KArg/binary, " >= -2147483648 andalso ", KArg/binary, " =< 2147483648 ) ">>,
                            <<>>};
                    TypeSize =:= null ->
                        {<<"( is_binary(", KArg/binary, ") )">>,
                            <<" andalso erl_mysql:illegal_character(", KArg/binary, ")">>};
                    DataType =:= binary ->
                        {<<"( is_binary(", KArg/binary, ") andalso byte_size(", KArg/binary, ") =< ", TypeSize/binary, ")">>,
                            <<" andalso erl_mysql:illegal_character(", KArg/binary, ")">>}
                end,
            if
                CheckNull =:= <<"">> ->
                    <<"validate('", K/binary, "', ", KArg/binary, ") -> ", CheckType/binary, Illegal/binary, ";\n">>;
                true ->
                    <<"validate('", K/binary, "', ", KArg/binary, ") -> ", CheckNull/binary, " orelse ", CheckType/binary, Illegal/binary, ";\n">>
            end
        end,
    <<(iolist_to_binary(lists:map(Fun, FieldsRecord)))/binary,
        "validate(_K, _V) ->
    io:format(\"error no field:~p~n\", [[_K, _V]]),
    false.">>.

to_default(Tab, ToRecord) ->
    {ToDefaultAcc, ToIndexAcc} = lists:foldl(
        fun({K, Default, _Comment}, {ToDefault, ToIndex}) ->
            if
                ToDefault =:= <<>> ->
                    {
                        <<"to_default(", K/binary, ") -> <<\"", Default/binary, "\">>">>,
                        <<"to_index(", K/binary, ") -> #", Tab/binary, ".", K/binary>>
                    };
                true ->
                    {
                        <<ToDefault/binary, ";\nto_default(", K/binary, ") -> <<\"", Default/binary, "\">>">>,
                        <<ToIndex/binary, ";\nto_index(", K/binary, ") -> #", Tab/binary, ".", K/binary>>
                    }
            end
        end, {<<>>, <<>>}, ToRecord),

    <<"

", ToDefaultAcc/binary, ".


", ToIndexAcc/binary, ".">>.



fun_arg(AccRecord) ->
    lists:foldl(
        fun({K, _Default, _Comment}, Fields) ->
            if
                Fields =:= <<>> -> <<"`", K/binary, "`">>;
                true -> <<Fields/binary, ", `", K/binary, "`">>
            end
        end, <<>>, AccRecord).

fun_can(Tab, Field, Variate) ->
    <<"\n        fun() -> validate(", Tab/binary, ", '", Field/binary, "', ", Variate/binary, ") end">>.

fun_where(Field, FieldArg, V) ->
    if
        is_integer(V) ->
            <<Field/binary, " = \",(integer_to_binary(", Field/binary, "))/binary, \"">>;
        is_binary(V) ->
            <<Field/binary, " = '\",", FieldArg/binary, "/binary, \"'">>
    end.