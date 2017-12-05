:-module(readwrite, [addtodatabase/5]).
:-use_module(library(file_systems)).
:-use_module(library(codesio)).
:-use_module(pokerrules).
:-use_module(dealer).
:-use_module(saver).

addtodatabase(P1, P2, Flop, Turn, River) :-
  playersevenCards(P1, Flop, Turn, River, P1seven),
  playersevenCards(P2, Flop, Turn, River, P2seven),
  playersixCards(P1, Flop, Turn, P1six),
  playersixCards(P2, Flop, Turn, P2six),
  playerfiveCards(P1, Flop, P1five),
  playerfiveCards(P2, Flop, P2five),
  handSort(P1, P1Sorted),
  handSort(P2, P2Sorted),
  whattowrite(3, P1, P1seven, Got, FiveBest, Writeriver1),
  whattowrite(2, P1, P1six, _A, _B, Writeturn1),
  whattowrite(1, P1, P1five, _C, _D, Writeflop1),
  whattowrite(3, P2, P2seven, Got2, FiveBest2, Writeriver2),
  whattowrite(2, P2, P2six, _E, _F, Writeturn2),
  whattowrite(1, P2, P2five, _G, _H, Writeflop2),
  HandP1 = [Writeflop1, Writeturn1, Writeriver1],
  HandP2 = [Writeflop2, Writeturn2, Writeriver2],
  winner(Got, Got2, Winner, FiveBest, FiveBest2),
  file_name(P1Sorted, P1Name),                              %find out what the name of the file is
  file_name(P2Sorted, P2Name),
  (Winner == p1 -> add(HandP1, win, P1Name), add(HandP2, loss, P2Name)  %only for preflop atm "preflop" can be replaced by anything
  ;Winner == p2 -> add(HandP1, loss, P1Name), add(HandP2, win, P2Name)
  ;Winner == tie -> !
  ).

file_name(This, FileName) :-
  format_to_codes('~p.txt', [This], Codes),
  name(FileName, Codes).

add(Hand, Win_or_loss, From) :-
  file_exists(From),
  find_and_write(Hand, From, 'temp.txt', Win_or_loss),
  delete_file(From),
  rename_file('temp.txt', From).

add(Hand, Win_or_loss, From) :-
  \+file_exists(From),
  open(From, append, Stream1),
  format(Stream1, 'total_WL(~d,~d).~n', [0,0]),
  close(Stream1),
  find_and_write(Hand, From, 'temp.txt', Win_or_loss),
  delete_file(From),
  rename_file('temp.txt', From).

find_and_write(Hand, First, Second, loss) :-
  open(First, read, Stream1),
  open(Second, append, Stream2),
  read(Stream1, total_WL(X, Y)),
  Total_loss is Y + 1,
  format(Stream2, 'total_WL(~d,~d).~n', [X,Total_loss]),
  file_search(Stream1, Stream2, Hand, loss),
  close(Stream1),
  close(Stream2).

find_and_write(Hand, First, Second, win) :-
  open(First, read, Stream1),
  open(Second, append, Stream2),
  read(Stream1, total_WL(X, Y)),
  Total_Win is X + 1,
  format(Stream2, 'total_WL(~d,~d).~n', [Total_Win,Y]),
  file_search(Stream1, Stream2, Hand, win),
  close(Stream1),
  close(Stream2).

%file_search(+Stream, +Hand, -Lines) uses the stream to find the hand
file_search(Stream1, Stream2, [Flop, Turn, River], Win_or_loss) :-
  \+at_end_of_stream(Stream1),
  read(Stream1, [Hands, X, Y]),
  (   Hands == Flop, Win_or_loss == win -> Won is X + 1, write(Stream2, [Flop, Won, Y]), write(Stream2, '.'), nl(Stream2), file_search(Stream1, Stream2, [[], Turn, River], Win_or_loss)
    ; Hands == Flop, Win_or_loss == loss -> Loss is Y + 1, write(Stream2, [Flop, X, Loss]), write(Stream2, '.'), nl(Stream2), file_search(Stream1, Stream2, [[], Turn, River], Win_or_loss)
    ; Hands == Turn, Win_or_loss == win -> Won is X + 1, write(Stream2, [Turn, Won, Y]), write(Stream2, '.'), nl(Stream2), file_search(Stream1, Stream2, [Flop, [], River], Win_or_loss)
    ; Hands == Turn, Win_or_loss == loss -> Loss is Y + 1, write(Stream2, [Turn, X, Loss]), write(Stream2, '.'), nl(Stream2), file_search(Stream1, Stream2, [Flop, [], River], Win_or_loss)
    ; Hands == River, Win_or_loss == win -> Won is X + 1, write(Stream2, [River, Won, Y]), write(Stream2, '.'), nl(Stream2), file_search(Stream1, Stream2, [Flop, Turn, []], Win_or_loss)
    ; Hands == River, Win_or_loss == loss -> Loss is Y + 1, write(Stream2, [River, X, Loss]), write(Stream2, '.'), nl(Stream2), file_search(Stream1, Stream2, [Flop, Turn, []], Win_or_loss)
    ; write(Stream2, [Hands, X, Y]), write(Stream2, '.'), nl(Stream2), file_search(Stream1, Stream2, [Flop, Turn, River], Win_or_loss)
    ).

file_search(S, Stream2, [Flop, Turn, River], Win_or_loss) :-
  at_end_of_stream(S),
  continued(S, Stream2, [Flop, Turn, River], Win_or_loss).



file_search(Stream1, Stream2, [[],[],[]], _) :-
  \+at_end_of_stream(Stream1),
  repeat,
  read(Stream1, X),
  write(Stream2, X), write(Stream2, '.'), nl(Stream2),
  X = end_of_file, !.


continued(_, _, [[],[],[]], _).

continued(S, Stream2, [Flop, Turn, River], win) :-
  Flop \== [],
  write(Stream2, [Flop, 1, 0]), write(Stream2, '.'), nl(Stream2),
  continued(S, Stream2, [[], Turn, River], win).
continued(S, Stream2, [Flop, Turn, River], win) :-
  Turn \== [],
  write(Stream2, [Turn, 1, 0]), write(Stream2, '.'), nl(Stream2),
  continued(S, Stream2, [Flop, [], River], win).
continued(_, Stream2, [_, _, River], win) :-
  River \== [],
  write(Stream2, [River, 1, 0]), write(Stream2, '.'), nl(Stream2), !.


continued(S, Stream2, [Flop, Turn, River], loss) :-
  Flop \== [],
  write(Stream2, [Flop, 0, 1]), write(Stream2, '.'), nl(Stream2),
  continued(S, Stream2, [[], Turn, River], loss).
continued(S, Stream2, [Flop, Turn, River], loss) :-
  Turn \== [],
  write(Stream2, [Turn, 0, 1]), write(Stream2, '.'), nl(Stream2),
  continued(S, Stream2, [Flop, [], River], loss).
continued(_, Stream2, [_, _, River], loss) :-
  River \== [],
  write(Stream2, [River, 0, 1]), write(Stream2, '.'), nl(Stream2), !.
