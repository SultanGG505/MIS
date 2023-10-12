:- dynamic(player/2).
:- dynamic(queen_moves/1).
:- dynamic(board_size/1).

start(Size,Level):-
    initGame(Board,Size),
    game(Board,Level).

game(Board,Level):-
    eatMovesList(player, Board, OptionMove),
    player(player,Types),
    ( OptionMove = [],!, %Free option - Normal move
    repeat,
    read((X1,Y1)),
    checkType(Board,(X1,Y1),Type),
    nonvar(Type),
    member(Type,Types),
    read((X2,Y2)),
    playerMove(player, Board, (X1,Y1), (X2,Y2), TempBoard1);
    %Else must eat move
    repeat,
    read((X1,Y1)),
    checkType(Board,(X1,Y1),Type),
    nonvar(Type),
    member(Type,Types),
    read((X2,Y2)),
    member([(X1,Y1),(X2,Y2)], OptionMove),
    playerMove(player, Board, (X1,Y1), (X2,Y2), TempBoard),
    eatCombo(player, TempBoard, X2, Y2, Type, TempBoard1)),

    %AI turn and try to find a winner
    (findWinner(TempBoard1,Winner, player),!,getBoard(TempBoard1),(Winner = "draw",!,write("It's draw...");write("The winner is "),write(Winner),write("!!!!!"));
    alpha_beta(computer,Level,TempBoard1,-200,200,Move,_),
    move(computer, TempBoard1, NewBoard, Move),
    getBoard(NewBoard),
    (findWinner(NewBoard,Winner, computer),!,(Winner = "draw",!,write("It's draw...");write("The winner is "),write(Winner),write("!!!!!"));game(NewBoard,Level))),!.

otherPlayer(player,computer).
otherPlayer(computer,player).

%############################# Initialization the game, build the board' put the stones, initialization players and rules #############################
initGame(Board,Size):-
    retractall(player(_,_)),
    retractall(queen_moves(_)),
    retractall(board_size(_)),
    getBoardSize(Size,BoardSize),
    initBoard(Board,BoardSize),
    getBoard(Board),
    assert(player(player, ["W","w"])),
    assert(player(computer, ["B","b"])),
    assert(queen_moves(0)),
    assert(board_size(BoardSize)).

getBoardSize(Size,BoardSize):-
    Size =< 6,!,BoardSize is 6 ; (Size >= 10,!,BoardSize is 10 ; BoardSize is 8).

initBoard(Board,BoardSize):-
    RowsToInit is ((BoardSize // 2)-1),
    initBoard(Board,RowsToInit,BoardSize),!.
initBoard([],0,_):-!.
initBoard(Board,N,BoardSize):-
    initBlackStones(BlackSide,N,BoardSize),
    initWhiteStones(WhiteSide,N,BoardSize),
    length(EmptyRow,BoardSize),
    append(BlackSide,[EmptyRow],Top),
    append([EmptyRow],WhiteSide,Bottom),
    append(Top,Bottom,Board),!.

initBlackStones(BlackBoard,Pos,BoardSize):-
    Size is BoardSize/2,
    initBlackStones(BlackBoard,Pos,1,Size),!.

initBlackStones([],_,N,N):-!.
initBlackStones([Row|BlackBoard],Pos,N,Size):-  
    (   1 =:= N mod 2,!,
    evenStone("B",Row,Size);
    oddStone("B",Row,Size)),
    N1 is N+1,
    initBlackStones(BlackBoard,Pos,N1,Size).
    
initWhiteStones(BlackBoard,Pos,BoardSize):-
    Size is BoardSize/2,
    initWhiteStones(BlackBoard,Pos,Pos,Size),!.

initWhiteStones([],_,0,_):-!.
initWhiteStones([Row|BlackBoard],Pos,N,Size):-
	(1 =:= N mod 2,!,
    oddStone("W",Row,Size);
    evenStone("W",Row,Size)),
    N1 is N-1,
    initWhiteStones(BlackBoard,Pos,N1,Size).    

evenStone(_,[],0):-!.
evenStone(Type,[_,Type|Row],Stones):-
    S is Stones - 1,
    evenStone(Type,Row,S),!.

oddStone(_,[],0):-!.
oddStone(Type,[Type,_|Row],Stones):-
    S is Stones - 1,
    oddStone(Type,Row,S),!.

%------ Draw board to console
getBoard(Board):-
    processBoard(Board,BoardResult),
    write(BoardResult),nl.

processBoard([],[]):-!.
processBoard([Row|Rows],[ProcessRow|ProcessRows]):-
    processRow(Row,ProcessRow),
    processBoard(Rows,ProcessRows).

processRow([],[]):-!.
processRow([X|Xs],["#"|Ys]):-
    var(X),processRow(Xs,Ys),!.
processRow([X|Xs],[X|Ys]):-
    processRow(Xs,Ys),!.    

%############################# Stone's and Queen's\King's Moves #############################
%------ Check legal target move
playerMove(Player, Board, (X1,Y1), (X2,Y2), NewBoard):-
    player(Player, Types),
    checkType(Board, (X1,Y1), Type),
    nonvar(Type),
    member(Type, Types),
    typeMove(Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard).

%------ Check type move
typeMove(Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard):-
    (Type = "B" ; Type = "W"),!,
    stoneMove(Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard);
    queenMove(Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard).

%------ Normal stone move
stoneMove(_Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard):-
    legalPos((X1,Y1), (X2,Y2)),
    normalMove(X1,X2),!,
    checkType(Board, (X2,Y2), Type2),
    stoneLegalMove(Type, X1, X2),
    normalMove(Y1,Y2),
    var(Type2),!,
    (changeType(Board, _, (X1,Y1), TempBoard), 
     changeType(TempBoard, Type, (X2,Y2), NewBoard)),
     restartQueenMoves,!.

%------ Stone eat move
stoneMove(Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard):-
    legalPos((X1,Y1), (X2,Y2)),
    eatMove(X1,X2),!,
    (getLegalMove((X1,Y1), (X2,Y2), X3, Y3),
     eatPostion(Board, (X1,Y1), (X2,Y2), (X3,Y3)),!,(
     changeType(Board, _, (X1,Y1), TempBoard),
     changeType(TempBoard, Type, (X2,Y2), TempBoard1),
     changeType(TempBoard1, _, (X3,Y3), NewBoard)),
     restartQueenMoves),!.

%------ Queen\King stone move
queenMove(_Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard):-
    legalPos((X1,Y1),(X2,Y2)),
    getLegalMove((X1,Y1),(X2,Y2),X1,Y1),
    checkType(Board,(X2,Y2),Type2),
    var(Type2),
    changeType(Board, _, (X1,Y1), TempBoard),
    changeType(TempBoard, Type, (X2,Y2), NewBoard),
    sequenceQueenMoves.

%------ Queen\King eat move
queenMove(Player, Type, Board, (X1,Y1), (X2,Y2), NewBoard):-
    legalPos((X1,Y1), (X2,Y2)),
    queenLegalMove(X1, X2, Y1, Y2),
    getLegalMove((X1,Y1), (X2,Y2), X3, Y3),
    checkType(Board, (X2,Y2), Type2),
    checkType(Board, (X3,Y3), Type3),
    var(Type2),
    freeWay(Board, (X1,Y1), (X3,Y3)),
    (nonvar(Type3),
    opponent(Type,Type3),
    changeType(Board, _, (X1,Y1), TempBoard),
    changeType(TempBoard, _, (X3,Y3), TempBoard1),
    changeType(TempBoard1, Type, (X2,Y2), NewBoard),
    restartQueenMoves;
    var(Type3),
    changeType(Board, _, (X1,Y1), TempBoard),
    changeType(TempBoard, Type, (X2,Y2), NewBoard)),
    sequenceQueenMoves.

%------ Check if have clear way between two points (for queen's\king's move)
freeWay(_, X, X):-!.       
freeWay(_, (X1,Y1), (X2,Y2)):-
    getLegalMove((X1,Y1), (X2,Y2), X1, Y1),!.  
freeWay(Board, (X1,Y1), (X2,Y2)):-
    getLegalMove((X1,Y1), (X2,Y2), X3, Y3),!,
    checkType(Board, (X3,Y3), Type),
    var(Type),
    freeWay(Board, (X1,Y1), (X3,Y3)).

%------ Normal move of normal stone is 2 steps
normalMove(X,Y):-
    R is X-Y,R = 1 ;
    R is Y-X, R = 1.

%------ Eat move of normal stone is 2 steps
eatMove(X,Y):-
    R is X-Y,R = 2 ;
    R is Y-X, R = 2.

eatPostion(Board, (X1,Y1), (X2,Y2), (X3,Y3)):-
    checkType(Board, (X1,Y1), Type),
    checkType(Board, (X2,Y2), Type2),
    checkType(Board, (X3,Y3), Type3),
    nonvar(Type3),
    opponent(Type,Type3),
    var(Type2).

%------ Check legal moves
legalPos((X1,Y1),(X2,Y2)):- 
    N1 is (X1 mod 2), 
    N1 =:= (Y1 mod 2), 
    N2 is (X2 mod 2), 
    N2 =:= (Y2 mod 2), 
    Y1 \= Y2, X1 \= X2.

%------ Stoune direction move
stoneLegalMove("W",X1,X2):-X1<X2.
stoneLegalMove("B",X1,X2):-X1>X2.

getLegalMove((X1,Y1),(X2,Y2),X3,Y3):-
    (X1<X2,!, X3 is X2-1 ; X3 is X2+1),
    (Y1<Y2,!, Y3 is Y2-1 ; Y3 is Y2+1).

%------ Queen\King direction move
queenLegalMove(X1,X2,Y1,Y2):-
    N1 is X1 - X2, N2 is Y1 - Y2, N1=N2,!.
queenLegalMove(X1,X2,Y1,Y2):-
    N1 is X2 - X1, N2 is Y1 - Y2, N1=N2,!.
queenLegalMove(X1,X2,Y1,Y2):-
    N1 is X1 - X2, N2 is Y2 - Y1, N1=N2,!.
queenLegalMove(X1,X2,Y1,Y2):-
    N1 is X2 - X1, N2 is Y2 - Y1, N1=N2,!.

%############################# Cheack, Delete and Change types (Update Board ruls) #############################
%------ Check type in row postions array
checkType(Board,(X,Y),Type):-
    findRow(Board,X,Row),
    findPostionType(Row,Y,Type),!.

findRow(Board,X,Row):-
    length(Board,L),
    N is (L+1)-X,
    getRow(Board,N,Row),!.
getRow([Row|_], 1, Row):-!.
getRow([_|Rows], N, Row):-
    N1 is N-1,
    getRow(Rows,N1,Row),!.

findPostionType([Type|_],1,Type):-!.
findPostionType([_|NextPos],N,Type):-
    N1 is N - 1,
    findPostionType(NextPos,N1,Type),!.

%------ Delete type of pos postion in row array, and send new row
changeType(Board,Type,(X,Y),NewBoard):-
    board_size(BoardSize),
    N is (BoardSize + 1) - X,
    (var(Type);findType(Type,X,NewType)),
    changeRow(Board,NewType,N,Y,NewBoard),!.

changeRow([Row|Rows],Type,1,Y,[NewRow|Rows]):-
    newType(Row,Type,Y,NewRow),!.
changeRow([Row|Rows],Type,N,Y,[Row|NewBoard]):-
    N1 is N-1,
    changeRow(Rows,Type,N1,Y,NewBoard),!.

newType([_|Row],Type,1,[Type|Row]):-!.
newType([X|Row],Type,N,[X|NewRow]):-
    N1 is N-1,
    newType(Row,Type,N1,NewRow),!.

%------ Change type in row x pos y, that it can happen whan stone
%------ upgrade to queen\king
findType(Type,X,NewType):-
    Type = "W",
    X = 8,!,
    NewType = "w";
    Type = "B",
    X = 1,!,
    NewType = "b";
    Type = NewType.

%------ Check if it's opponent value
opponent(Player,Opp):-
    nonvar(Player),
    (Player="W";Player="w"),
    nonvar(Opp),
    (Opp="B";Opp="b").
opponent(Player,Opp):-
    nonvar(Player),
    (Player="B";Player="b"),
    nonvar(Opp),
    (Opp="W";Opp="w").

%############################# Eat Rules #############################
%------ List of Lists for AI eat moves
eatComboLists(Player, Board ,Moves):-
    player(Player,Types),
    findall(Move,
    (xyPos(X1,Y1),
     checkType(Board, (X1,Y1), Type),
     nonvar(Type),
     member(Type, Types),
     comboList(Player, Board, (X1,Y1), Type, Move),
     length(Move,N),N>1), Moves),!.
eatComboLists(_,_,[]):-!.

comboList(Player,Board, (X1,Y1), Type, [(X1,Y1)|Move]):-
    xyPos(X2,Y2),
    legalPos((X1,Y1), (X2,Y2)),
    eatable(Board, (X1,Y1), (X2,Y2), Type),
    playerMove(Player, Board, (X1,Y1), (X2,Y2), TempBoard),
    comboList(Player,TempBoard,(X2,Y2),Type,Move),!.
comboList(_, _, (X1,Y1), _, [(X1,Y1)]):-!.

%------ List of the moves the player need to play
%------ When stone or queen\king must to eat 
eatMovesList(Player, Board ,Targets):-
    player(Player,Types),
    findall([(X1,Y1), (X2,Y2)],
    (xyPos(X1,Y1),
    xyPos(X2,Y2),
     legalPos((X1,Y1), (X2,Y2)),
     checkType(Board, (X1,Y1), Type),
     nonvar(Type),
     member(Type, Types),
     eatable(Board, (X1,Y1), (X2,Y2), Type)), Targets),!.
eatMovesList(_,_,[]):-!.

eatable(Board, (X1,Y1), (X2,Y2), _Type):-
    Y1 \= Y2, X1 \= X2,
    eatMove(X1,X2),
    eatMove(Y1,Y2),
    getLegalMove((X1,Y1), (X2,Y2), X3, Y3),
    eatPostion(Board, (X1,Y1), (X2,Y2), (X3,Y3)),!.
eatable(Board,(X1,Y1),(X2,Y2),Type):-
    (   Type = "w" ; Type = "b"),  
    X1 \= X2, Y1 \= Y2,
    queenLegalMove(X1, X2, Y1, Y2),
    getLegalMove((X1,Y1), (X2,Y2), X3, Y3),
    eatPostion(Board, (X1,Y1), (X2,Y2), (X3,Y3)),
    freeWay(Board, (X1,Y1), (X3,Y3)).

eatCombo(Player, Board, X, Y, Type, NewBoard):-
    eatMovesList(Player, Board, OptionMove),
    findall([(X,Y),(X2,Y2)],(member([(X,Y),(X2,Y2)],OptionMove)),Targets),
    (Targets = [],!,NewBoard = Board;
    getBoard(Board),
    repeat,
    read((X1,Y1)),
    member([(X,Y),(X1,Y1)],Targets),!,
    playerMove(Player, Board, (X,Y), (X1,Y1), TempBoard), 
    eatCombo(Player, TempBoard, X1, Y1, Type, NewBoard)).

%############################# Find Winner - Win Rules #############################
%------ Find winner
findWinner(Board,Winner, PlayerTurn):-
    countStones(Board,(WS,QWS,BS,QBS),100),%DOTO - cantMove only on the next turn player
    ((WS = 0, QWS = 0 ; PlayerTurn = computer, cantMove(player,Board)),!, Winner = computer;%One Player have no stone on the board - he loses
     (BS = 0, QBS = 0 ; PlayerTurn = player, cantMove(computer,Board)),!, Winner = player);%Or someone cant move
    queen_moves(15),!, %When the last 15 ture it was a queen's moves - draw
    Winner = "draw".

%------ When one of the player (and it's his turn) cant move or eat - he loses
cantMove(Player, Board):- 
    findMove(Player, Board ,Moves),
    (Moves \= [],!,false;true).

findMove(Player, Board, Moves):-
    (eatMovesList(Player, Board,EatMoves),EatMoves \= [],!,Moves = EatMoves; 
    player(Player,Types),
    xyPos(X1,Y1),
    xyPos(X2,Y2),
    legalPos((X1,Y1), (X2,Y2)),
    checkType(Board, (X1,Y1), Type1),
    checkType(Board, (X2,Y2), Type2),
    nonvar(Type1),
    var(Type2),
    member(Type1,Types),
    (stoneLegalMove(Type1,X1,X2),
    normalMove(Y1,Y2),
    normalMove(X1,X2);
    (Type1 = "w" ; Type1 = "b"),
    queenLegalMove(X1, X2, Y1, Y2),
    freeWay(Board, (X1,Y1), (X2,Y2))),
    Moves = [(X1,Y1),(X2,Y2)]),!.
findMove(_,_,[]):-!.

sequenceQueenMoves:-
    queen_moves(N),
    N1 is N + 1,
    retract(queen_moves(_)),
    assert(queen_moves(N1)).

sameQueenMove:-
    queen_moves(N),
    N1 is N - 1,
    retract(queen_moves(_)),
    assert(queen_moves(N1)).    

restartQueenMoves:-
    retract(queen_moves(_)),
    assert(queen_moves(0)).

%------ Counting stones anf queens\kings for every player
countStones([],(0,0,0,0),_):-!.
countStones([Row|Rows],(WS,QWS,BS,QBS),H):-
    H1 is H-1,
    countStones(Rows,(WS1,QWS1,BS1,QBS1),H1),!,
    countInRow(Row,(WS2,QWS2,BS2,QBS2),H),!,
    WS is WS1 + WS2,
    QWS is QWS1 + QWS2,
    BS is BS1 + BS2,
    QBS is QBS1 + QBS2.

countInRow([],(0,0,0,0),_):-!.
countInRow([X|Xs],(WS,QWS,BS,QBS),H):-
    var(X),countInRow(Xs,(WS,QWS,BS,QBS),H).
countInRow(["W"|Xs], (WS,QWS,BS,QBS),H):-
    countInRow(Xs, (WS1,QWS,BS,QBS),H),
    WS is WS1 + H.
countInRow(["w"|Xs], (WS,QWS,BS,QBS),H):-
	countInRow(Xs, (WS,QWS1,BS,QBS),H),
    QWS is QWS1+1.
countInRow(["B"|Xs], (WS,QWS,BS,QBS),H):-
    countInRow(Xs, (WS,QWS,BS1,QBS),H),
    board_size(BoardSize),
    BS is BS1 +(BoardSize+1-H).
countInRow(["b"|Xs], (WS,QWS,BS,QBS),H):-
    countInRow(Xs, (WS,QWS,BS,QBS1),H),
    QBS is QBS1+1.

%############################# AI - Alpha Beta #############################
alpha_beta(Player,_,Board,_,_,_,Value):-
   staticval(Player,Board,Value),(Value =< -200;Value >= 200),!.

alpha_beta(Player,0,Board,_,_,_,Value):-
   staticval(Player,Board,Value),!.

alpha_beta(Player,Depth,Board,Alpha,Beta,Move,Value):-
    Depth>0,
    all_AI_Moves(Player,Board,Moves),
    Alpha1 is -Beta,
    Beta1 is -Alpha,
    Depth1 is Depth-1,
    boundedbest(Player,Moves,Board,Depth1,Alpha1,Beta1,nil,(Move,Value)),!.

%------Calling to move rules and get the data from alpha beta tree
boundedbest(Player,[Move|Moves],Board,D,Alpha,Beta,Record,BestMove):-
    moves(Player, Board, NewBoard,Move),
    otherPlayer(Player,OtherPlayer),
    alpha_beta(OtherPlayer,D,NewBoard,Alpha,Beta,_,Value),
    Value1 is -Value,
    newbounds(Player,Move,Value1,D,Alpha,Beta,Moves,Board,Record,BestMove).
boundedbest(_,[],_,_,Alpha,_,Move,(Move,Alpha)).

%------Change the alpha beta values
newbounds(_,Move,Value,_,_,Beta,_,_,_,(Move,Value)):-
    Value >= Beta, !.
newbounds(Player,Move,Value,D,Alpha,Beta,Moves,Board,_,BestMove):-
    Alpha < Value,Value < Beta,!,
    boundedbest(Player,Moves,Board,D,Value,Beta,Move,BestMove).
newbounds(Player,_,Value,D,Alpha,Beta,Moves,Board,Record,BestMove):-
    Value =< Alpha, !,
    boundedbest(Player,Moves,Board,D,Alpha,Beta,Record,BestMove).    

%------If AI cant move - lose postion
%------If player cant move - win postion
%------Else we calculet the number of stones (1 score of any stone), and the queens\kings (2 score)
staticval(Player,Board, Val):-
    board_size(BoardSize),
    countStones(Board,(WS,QWS,BS,QBS),BoardSize),
    ComputerScore is BS + ((BoardSize+4)*QBS),
    PlayerScore is WS + ((BoardSize+4)*QWS),
    (Player = computer,!, (ComputerScore = 0,!,Val = -200 ;(PlayerScore = 0,!,Val = 200; Val is ComputerScore - PlayerScore));
    (PlayerScore = 0,!,Val = -200 ; (ComputerScore = 0,!,Val = 200 ;Val is PlayerScore - ComputerScore))),!.

%------Normal move, eat move and combo eat move
moves(Player, Board, NewBoard, MoveList):-
    move(Player, Board, NewBoard, MoveList),!.

move(Player, Board, NewBoard, [(X,Y)|Combo]):-
   checkType(Board, (X,Y), Type),
   aiMove(Player, Type, Board, NewBoard, [(X,Y)|Combo]),!.

aiMove(Player, _Type, Board, NewBoard, [(X1,Y1),(X2,Y2)]):-
    playerMove(Player, Board, (X1,Y1), (X2,Y2), NewBoard),!.
aiMove(Player, Type, Board, NewBoard, [(X1,Y1),(X2,Y2)|Combo]):-
    getLegalMove((X1,Y1), (X2,Y2), X3, Y3),
    changeType(Board, _, (X1,Y1), TempBoard),
    changeType(TempBoard, _, (X3,Y3), TempBoard1),
    changeType(TempBoard1, Type, (X2,Y2), TempBoard2),
    aiMove(Player, Type, TempBoard2, NewBoard, [(X2,Y2)|Combo]),!.

all_AI_Moves(Player, Board, Moves):-
    (eatComboLists(Player, Board,EatMoves),EatMoves \= [],!,Moves = EatMoves; 
    player(Player,Types),
    findall([(X1,Y1),(X2,Y2)],
    (xyPos(X1,Y1),
    xyPos(X2,Y2),
    legalPos((X1,Y1), (X2,Y2)),
    checkType(Board, (X1,Y1), Type1),
    checkType(Board, (X2,Y2), Type2),
    nonvar(Type1),
    var(Type2),
    member(Type1,Types),
    (stoneLegalMove(Type1,X1,X2),
    normalMove(Y1,Y2),
    normalMove(X1,X2);
    (Type1 = "w" ; Type1 = "b"),
    queenLegalMove(X1, X2, Y1, Y2),
    freeWay(Board, (X1,Y1), (X2,Y2)))),Moves)),!.
all_AI_Moves(_,_,[]):-!.

xyPos(X1,X2):-
    board_size(8),!,(
    member(X1, [1,3,5,7]),
    member(X2, [1,3,5,7]);
    member(X1, [2,4,6,8]),
    member(X2, [2,4,6,8]));
    ( board_size(10),!,
    (member(X1, [1,3,5,7,9]),
    member(X2, [1,3,5,7,9]);
    member(X1, [2,4,6,8,10]),
    member(X2, [2,4,6,8,10]);
    (member(X1, [1,3,5]),
    member(X2, [1,3,5]);
    member(X1, [2,4,6]),
    member(X2, [2,4,6])))).
