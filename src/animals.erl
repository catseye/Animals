%%% BEGIN animals.erl %%%
%%%
%%% animals - Classic 'expert system' game of Animals, in Erlang
%%%
%%% This work is in the public domain.  See UNLICENSE for more information.
%%%

%% @doc The classic 'expert system' demonstration game of Animals.
%%
%% This game stores a 'knowledge tree' about the animals it knows
%% in a nested tuple structure.  This is mainly to demonstrate how
%% one can work with binary trees as Erlang terms.  A more
%% serious implementation would probably use a real database
%% system, such as Mnesia.
%%
%% @end

-module(animals).
-vsn('$Id: animals.erl 531 2010-04-29 20:05:21Z cpressey $').
-author('cpressey@catseye.tc').
-copyright('This work is in the public domain; see UNLICENSE for more info').

-export([start/0]).

%% @spec start() -> ok
%% @doc Plays a game of Animals.

start() ->
  io:fwrite("Welcome to the game of Animals!~n~n"),
  Animals = case get_y_or_n("Would you like to load the animals from disk? ") of
    true ->
      load();
    false ->
      {animal, "horse"}
  end,
  loop(Animals).
loop(Animals) ->
  io:fwrite("OK, think of an animal, and I will try to guess what it is.~n"),
  NewAnimals = guess(Animals, Animals),
  io:fwrite("Now I know ~p animals!~n", [num_leaves(NewAnimals)]),
  case get_y_or_n("Would you like to play again? ") of
    true ->
      loop(NewAnimals);
    false ->
      case get_y_or_n("Would you like to save the animals to disk? ") of
        true ->
          save(NewAnimals),
          ok;
        false ->
          ok
      end
  end.

%% @spec guess(tree(), tree()) -> tree()
%% @doc Guesses an animal and receives a response from the player.
%% Using this response, it refines its guess, or learns a new animal.

guess({question, Question, TrueTree, FalseTree}, AllAnimals) ->
  case get_y_or_n(io_lib:format("~s? ", [Question])) of
    true ->
      guess(TrueTree, AllAnimals);
    false ->
      guess(FalseTree, AllAnimals)
  end;
guess({animal, Animal}, AllAnimals) ->
  case get_y_or_n(io_lib:format("Is it ~s? ", [indefart(Animal)])) of
    true ->
      io:fwrite("Yay!~n"),
      AllAnimals;
    false ->
      io:fwrite("I give up.~n"),
      NewAnimal = get_animal_name(),
      io:fwrite("And what question would distinguish between ~s and ~s?~n",
        [indefart(Animal), indefart(NewAnimal)]),
      NewQuestion = get_question(),
      case get_y_or_n(io_lib:format(
       "And what would be the answer that would indicate ~s? ",
       [indefart(NewAnimal)])) of
        true ->
          replace(AllAnimals,
            {animal, Animal}, {question, NewQuestion,
              {animal, NewAnimal}, {animal, Animal}});
        false ->
          replace(AllAnimals,
            {animal, Animal}, {question, NewQuestion,
              {animal, Animal}, {animal, NewAnimal}})
      end
  end.

%%% High-level Utilities

%% @spec load() -> tree()
%% @doc Loads the animal knowledge tree from <code>animals.dat</code>.

load() ->
  case file:consult(filename:join([code:priv_dir(animals), "animals.dat"])) of
    {ok, [Animals]} ->
      Animals;
    _ ->
      io:fwrite("Sorry, I couldn't read the file 'animals.dat'.~n"),
      {animal, "horse"}
  end.

%% @spec save(tree()) -> ok | {error, Reason}
%% @doc Saves the animal knowledge tree to <code>animals.dat</code>.

save(Animals) ->
  case file_dump(filename:join([code:priv_dir(animals), "animals.dat"]),
   [Animals]) of
    {ok, [Animals]} ->
      ok;
    Else ->
      io:fwrite("Sorry, I couldn't write to the file 'animals.dat'.~n"),
      Else
  end.

%% @spec replace(tree(), leaf(), tree()) -> tree()
%% @doc Returns a new tree with the specified leaf replaced by the
%% given subtree.

replace({question, Question, TrueTree, FalseTree}, Target, Replacement) ->
  {question, Question,
    replace(TrueTree, Target, Replacement),
    replace(FalseTree, Target, Replacement)};
replace(Target, Target, Replacement) ->
  Replacement;
replace({animal, Animal}, _Target, _Replacement) ->
  {animal, Animal}.

%% @spec num_leaves(tree()) -> integer()
%% @doc Returns the number of leaves in the given tree.

num_leaves({question, _Question, TrueTree, FalseTree}) ->
  num_leaves(TrueTree) + num_leaves(FalseTree);
num_leaves({animal, _Animal}) -> 1.

%% @spec indefart(string()) -> string()
%% @doc Returns a string with the appropriate indefinate article prepended
%% to the given noun.

indefart(Noun) ->
  case hd(uc(Noun)) of
    N when N == $A; N == $E; N == $I; N == $O; N == $U ->
      "an " ++ Noun;
    _ ->
      "a " ++ Noun
  end.

%% @spec get_y_or_n(string()) -> boolean()
%% @doc Gets a yes-or-no response from the player.

get_y_or_n(Prompt) ->
  io:fwrite("~s", [Prompt]),
  Response = io:get_line(''),
  case string:strip(uc(Response)) of
    "Y" ++ _Remainder ->
      true;
    "N" ++ _Remainder ->
      false;
    _ ->
      io:fwrite("Please answer 'yes' (or just 'y') or no (or just 'n').~n"),
      get_y_or_n(Prompt)
  end.

%% @spec get_animal_name() -> string()
%% @doc Gets the name of an animal from the player.

get_animal_name() ->
  io:fwrite("What was the name of the animal you were thinking of? "),
  case chomp(io:get_line('')) of
    "" ->
      io:fwrite("Sorry, I didn't quite catch that.~n"),
      get_animal_name();
    AnimalName ->
      lc(AnimalName)
  end.

get_question() ->
  case chomp(io:get_line('> ')) of
    "" ->
      io:fwrite("Sorry, I didn't quite catch that.~n"),
      get_question();
    Question ->
      strip_question_marks([to_upper(hd(Question)) | tl(Question)])
  end.

%%% Low-level Utilities

strip_question_marks(String) ->
  lists:reverse(strip_question_marks0(lists:reverse(String))).

strip_question_marks0([$? | Rest]) ->
  strip_question_marks0(Rest);
strip_question_marks0(Else) ->
  Else.

%% @spec chomp(string()) -> string()
%% @doc Removes all newlines from the end of a string.
%% Should work on both Unix and MS-DOS newlines.

chomp([]) -> [];
chomp(List) when is_list(List) ->
  lists:reverse(chomp0(lists:reverse(List))).
chomp0([]) -> [];
chomp0([H | T]) when H == 10; H == 13 -> chomp0(T);
chomp0([_ | _]=L) -> L.

%% @spec uc(string()) -> string()
%% @doc Translates a string to uppercase. Also flattens the list.

uc(L) -> uc(L, []).
uc([], A) -> A;
uc([H|T], A) -> uc(T, A ++ [uc(H)]);
uc(L, _) -> to_upper(L).

to_upper(X) when X >= $a, X =< $z -> X + ($A - $a);
to_upper(X)                       -> X.

%% @spec lc(string()) -> string()
%% @doc Translates a string to lowercase. Also flattens the list.

lc(L) -> lc(L, []).
lc([], A) -> A;
lc([H|T], A) -> lc(T, A ++ [lc(H)]);
lc(L, _) -> to_lower(L).

to_lower(X) when X >= $A, X =< $Z -> X + ($a - $A);
to_lower(X)                       -> X.

%% @spec file_dump(filename(), [term()]) -> {ok, [term()]} | {error, Reason}
%% @doc Writes all terms to a file.  Complements file:consult/1.

file_dump(Filename, List) ->
  case file:open(Filename, [write]) of
    {ok, Device} ->
      lists:foreach(fun(Term) ->
                      io:fwrite(Device, "~p.~n", [Term])
		    end, List),
      file:close(Device),
      {ok, List};
    Other ->
      Other
  end.

%%% END of animals.erl %%%
