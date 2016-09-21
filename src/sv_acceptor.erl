%%-------------------------------------------------------------------
%%
%% Copyright (c) 2016, James Fish <james@fishcakez.com>
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License. You may obtain
%% a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied. See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%%-------------------------------------------------------------------
%% @doc This module provides `safetyvalve' rate limiting of an `acceptor' in an
%% `acceptor_pool'. It is an `acceptor' with arguments: `{Queue, Mod, Arg}',
%% where `Queue' is the `safetyvalve' queue. `Mod' and `Arg' is the `acceptor'
%% callback module and its argument to be regulated. The task lasts for the life
%% time of the `acceptor' process to allow `safetyvalve' to limit concurrency of
%% open connections.
-module(sv_acceptor).

-behaviour(acceptor).

%% acceptor api

-export([acceptor_init/3]).
-export([acceptor_continue/3]).
-export([acceptor_terminate/2]).

%% acceptor api

acceptor_init(SockName, Sock, {Queue, Mod, Args}) ->
    case sv:ask(Queue, sv:timestamp()) of
        {go, Ref}  -> init(SockName, Sock, Queue, Ref, Mod, Args);
        {error, _} -> ignore
    end.

acceptor_continue(PeerName, Sock, {_Queue, _Ref, Mod, State}) ->
    Mod:acceptor_continue(PeerName, Sock, State).

acceptor_terminate(Reason, {Queue, Ref, Mod, State}) ->
    try
        sv:done(Queue, Ref, sv:timestamp())
    after
        Mod:acceptor_terminate(Reason, State)
    end.

%% internal

init(SockName, Sock, Queue, Ref, Mod, Args) ->
    try Mod:acceptor_init(SockName, Sock, Args) of
        Result       -> handle_init(Result, Queue, Ref, Mod)
    catch
        throw:Result -> handle_init(Result, Queue, Ref, Mod)
    end.

handle_init({ok, State}, Queue, Ref, Mod) ->
    {ok, {Queue, Ref, Mod, State}};
handle_init({ok, State, Timeout}, Queue, Ref, Mod) ->
    {ok, {Queue, Ref, Mod, State}, Timeout};
handle_init(Other, _, _, _) ->
    Other.
