-- module Movechecker
-- ( getmoves
-- , validmove
-- , incheck
-- , stalemate
-- , checkmate
-- , notabletomove
-- , attacked
-- , gameover
-- , makestate
-- , domove
-- , getsudomoves
-- ) where
module Movechecker where
--Necessary imports
import Types
import Chess
import Helpers
import Data.Bits

--FOR TESTING ONLY
import Boards
import Printing

state = makestate bbinit True


-- Returns a list of up to four potentially legal pawn moves
getpawnmoves :: State -> Position -> [Move]
getpawnmoves (State {board = bb, turn = False}) p =
  let m1 = if empty bb (p + 8) then [(p,p+8)] else []
      m2 = if row p == 1 && empty bb (p+8) && empty bb (p+16) then (p,p+16):m1 else m1
      m3 = if col p /= 0 && (isenemy bb (p+7) False) then (p,p+7):m2 else m2
      m4 = if col p /= 0 && (isenemy bb (p+9) False) then (p,p+9):m3 else m3
  in m4
getpawnmoves (State {board = bb, turn = True}) p =
  let m1 = if empty bb (p-8) then [(p,p-8)] else []
      m2 = if row p == 6 && empty bb (p-8) && empty bb (p-16) then (p,p-16):m1 else m1
      m3 = if col p /= 7 && (isenemy bb (p-7) True) then (p,p-7):m2 else m2
      m4 = if col p /= 7 && (isenemy bb (p-9) True) then (p,p-9):m3 else m3
  in m4


--returns a list of potentially legal rook moves
getrookmoves :: State -> Position -> [Move]
getrookmoves (State {board = bb, turn = t}) p  =
  let checkup acc pos    | pos < 0             = acc
                         | isenemy bb pos t    = (p,pos):acc
                         | empty bb pos        = checkup ((p,pos):acc) (pos-8)
                         | otherwise           = acc
      checkdown acc pos  | pos > 63            = acc
                         | isenemy bb pos t    = (p,pos):acc
                         | empty bb pos        = checkdown ((p,pos):acc) (pos+8)
                         | otherwise           = acc
      checkleft acc pos  | col pos == 0        = acc
                         | isenemy bb pos t    = (p,pos):acc
                         | empty bb pos        = checkleft ((p,pos):acc) (pos-1)
                         | otherwise           = acc
      checkright acc pos | col pos == 7        = acc
                         | isenemy bb pos t    = (p,pos):acc
                         | empty bb pos        = checkright ((p,pos):acc) (pos+1)
                         | otherwise           = acc
  in checkup [] (p-8) ++ checkdown [] (p+8) ++ checkleft [] (p-1) ++ checkright [] (p+1)

--returns a list of potentially legal knight moves
-- WARNING may need inrange, i removes it
getknightmoves :: State -> Position -> [Move]
getknightmoves (State {board = b, turn = t}) p =
  let m1 = if notfriendlyfire b (p,p+10) && row p < 7 && col p < 6 then [(p,p+10)]  else []
      m2 = if notfriendlyfire b (p,p+17) && row p < 6 && col p < 7 then (p,p+17):m1 else m1
      m3 = if notfriendlyfire b (p,p+15) && row p < 6 && col p > 0 then (p,p+15):m2 else m2
      m4 = if notfriendlyfire b (p,p+6)  && row p < 7 && col p > 1 then (p,p+6 ):m3 else m3
      m5 = if notfriendlyfire b (p,p-10) && row p > 0 && col p > 1 then (p,p-10):m4 else m4
      m6 = if notfriendlyfire b (p,p-17) && row p > 1 && col p > 0 then (p,p-17):m5 else m5
      m7 = if notfriendlyfire b (p,p-15) && row p > 1 && col p < 7 then (p,p-15):m6 else m6
      m8 = if notfriendlyfire b (p,p-6)  && row p > 0 && col p < 6 then (p,p-6 ):m7 else m7
  in m8

-- --checks the knight movement type so that it cannot travel accross the board
-- nmovement :: Move -> Bool
-- nmovement (o,d) = True --((abs (row o - row d) * (abs (col o - col d))) == 2)

getbishopmoves :: State -> Position -> [Move]
getbishopmoves (State {board = bb, turn = t}) p =
  let checkupleft acc pos    | row pos == 0 || col pos == 0    = acc
                             | isenemy bb pos t                = (p,pos):acc
                             | empty bb pos                    = checkupleft ((p,pos):acc) (pos-9)
                             | otherwise                       = acc
      checkdownleft acc pos  | row pos == 7 || col pos == 0    = acc
                             | isenemy bb pos t                = (p,pos):acc
                             | empty bb pos                    = checkdownleft ((p,pos):acc) (pos+7)
                             | otherwise                       = acc
      checkdownright acc pos | row pos == 7 || col pos == 7    = acc
                             | isenemy bb pos t                = (p,pos):acc
                             | empty bb pos                    = checkdownright ((p,pos):acc) (pos+9)
                             | otherwise                       = acc
      checkupright acc pos   | row pos == 0 || col pos == 7    = acc
                             | isenemy bb pos t                = (p,pos):acc
                             | empty bb pos                    = checkupright ((p,pos):acc) (pos-7)
                             | otherwise                       = acc
  in checkupleft [] (p-9) ++ checkdownleft [] (p+7) ++ checkdownright [] (p+9) ++ checkupright [] (p-7)



--gets a list of all potentially valid king moves including castling
getkingmoves :: State -> Position -> [Move]
getkingmoves s p =
  let b = board s
      m1 = if notfriendlyfire b (p,p+1) && col p < 7              then [(p,p+1)]  else []
      m2 = if notfriendlyfire b (p,p+9) && row p < 7 && col p < 7 then (p,p+9):m1 else m1
      m3 = if notfriendlyfire b (p,p+8) && row p < 7              then (p,p+8):m2 else m2
      m4 = if notfriendlyfire b (p,p+7) && row p < 7 && col p > 0 then (p,p+7):m3 else m3
      m5 = if notfriendlyfire b (p,p-1) && col p > 0              then (p,p-1):m4 else m4
      m6 = if notfriendlyfire b (p,p-9) && row p > 0 && col p > 0 then (p,p-9):m5 else m5
      m7 = if notfriendlyfire b (p,p-8) && row p > 0              then (p,p-8):m6 else m6
      m8 = if notfriendlyfire b (p,p-7) && row p > 0 && col p < 7 then (p,p-7):m7 else m7
  in m8


--gets list of potentially valid moves by castling
getcastlemoves :: State -> Position -> [Move]
getcastlemoves s p | turn s =
  let m1 = if (wl s) && whitecastle s (p, p+2) then [(p,p+2)]    else []
      m2 = if (ws s) && whitecastle s (p, p-2) then (p,p-2):m1   else m1
  in m2
getcastlemoves s p =
  let m1 = if (bl s) && blackcastle s (p, p+2) then [(p,p+2)]    else []
      m2 = if (bs s) && blackcastle s (p, p-2) then (p,p-2):m1   else m1
  in m2


--gets a list of moves for the current board, pass in zero to test the entire board
--returns moves which might put the player in check
getsudomoves :: State -> [Move]
--getsudomoves s = concat $ map (\n -> getmovesforspot s (index (board s) n) n) (toList ((if turn s then whitepieces else blackpieces) s))
getsudomoves s = (\n -> getmovesforspot s (getspot (board s) n) n) =<< [0 .. 63]

--returns a list of moves for a given spot at a specified position
getmovesforspot :: State -> Piece -> Position -> [Move]
getmovesforspot s p n | fromEnum p == 1 || fromEnum p == 7  = getpawnmoves   s n
getmovesforspot s p n | fromEnum p == 2 || fromEnum p == 8  = getknightmoves s n
getmovesforspot s p n | fromEnum p == 3 || fromEnum p == 9  = getbishopmoves s n
getmovesforspot s p n | fromEnum p == 4 || fromEnum p == 10 = getrookmoves   s n
getmovesforspot s p n | fromEnum p == 5 || fromEnum p == 11 = getbishopmoves s n ++ getrookmoves   s n
getmovesforspot s p n | fromEnum p == 6 || fromEnum p == 12 = getkingmoves   s n ++ getcastlemoves s n
getmovesforspot s _   n = []


--TODO everything below this
--gets filtered and legal moves
getmoves :: State -> [Move]
getmoves s = Prelude.filter (notcheckmove s) $ getsudomoves s

--TODO updated getmoves function
validmove :: State -> Move -> Bool
validmove s (o,d) = (o,d) `elem` getmoves s

notcheckmove :: State -> Move -> Bool
notcheckmove s (o,d) = (shiftL 1 (fromEnum d)).&.enemyattacks == 0 where enemyattacks = if turn s then blackattacks s else whiteattacks s

--returns true if and only if the current sides king can be attacked by an enemy piece
incheck :: State -> Bool
incheck s  = (king.&.enemyattacks) == 1
  where king = if turn s then whitekings (board s) else blackkings (board s)
        enemyattacks = if turn s then blackattacks s else whiteattacks s

--returns true if the current player is in checkmate or stalemate
gameover :: State -> Bool
gameover s = (checkmate s) || (stalemate s)

--not in check and not able to move
stalemate :: State -> Bool
stalemate s = not (incheck s) && notabletomove s (getsudomoves s)

--as soon as a valid move is seen (a move that does not put itself in check) False is returned else True
-- TODO fix this
notabletomove :: State -> [Move] -> Bool
notabletomove s m = not $ False `elem` (map (\x -> incheck s) m)

--in check and not able to move
checkmate :: State -> Bool
checkmate s = incheck s && notabletomove s (getsudomoves s)

--returns true if and only if the square is attacked by the current player
-- attacked :: State -> Maybe Int -> Bool
-- attacked s Nothing  = False
-- attacked s (Just i) | turn s    = i `elem` (whiteattacks s)
--                     | otherwise = i `elem` (blackattacks s)

--TODO
updateattacks :: State -> State
updateattacks s | turn s    = s
                | otherwise = s

--this is a helper function that makes a state out of all of the specified information and stores it for function use.
makestate :: BitBoard -> Side -> State
makestate b t = updateattacks State {
  board = b,
  turn = t,
  history = [],
  whiteattacks = 0,
  blackattacks = 0,
  wl = True,
  ws = True,
  bl = True,
  bs = True}

domove :: State -> Move -> State
domove s m = updateattacks (dmove s m)










--comment
