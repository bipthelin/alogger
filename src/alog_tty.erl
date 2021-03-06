%% @doc
%% Easy logger that logs messages to console (maiking io:format).
%% All functions in this logger are just gen_alog callbacks, so they
%% are private.
%% @end
%% ----------------------------------------------------------------------
%% Copyright (c) 2011 Siberian Fast Food
%% Authors: Alexander Dergachev <alexander.dergachev@gmail.com>
%%          Artem Golovinsky    <artemgolovinsky@gmail.com>
%%          Igor Karymov        <ingham.k@gmail.com>
%%          Dmitry Groshev      <lambdadmitry@gmail.com>
%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% ----------------------------------------------------------------------

-module(alog_tty).
-behaviour(gen_alog).

%% gen_alog callbacks
-export([start/1,
         stop/1,
         log/2]).

%% @private
-spec start(list()) -> ok.
start(_) ->
    ok.

%% @private
-spec stop(list()) -> ok.
stop(_) ->
    ok.

%% @private
-spec log(integer(), string()) -> ok.
log(_ALoggerPrio, Msg) ->
    case node(group_leader()) =:= node() of
        true ->
            io:format("~s", [Msg]);
        _ ->
            ok
    end.
