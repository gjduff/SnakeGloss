-- Game.hs
-- the game-models and operations

module Game ( GridSize 
            , Pos
            , Snake
            , Apples
            , Walls
            , Score
            , Direction 
            , Input (..)
            , GameState (..)
            , stepGame
            , reactGame
            , initGame
            , snakeBody 
            , snakePos
            ) where

import qualified Data.Set as Set
import qualified Data.List as List

type GridSize = (Int, Int)
type Pos      = (Int, Int)

data Snake 
    = MkSnake 
        { body :: [Pos]
        , isGrowing :: Bool 
        } deriving (Show, Eq)
type Apples    = Set.Set Pos
type Walls     = Set.Set Pos
type Score     = Int

data Direction 
  = MoveRight 
  | MoveLeft 
  | MoveUp 
  | MoveDown
  deriving (Show, Eq)

data Input
  = KeyDown
  | KeyUp
  | KeyLeft
  | KeyRight
  deriving (Show, Eq)

data GameState 
  = GameState   
    { snake     :: Snake
    , apples    :: Apples
    , walls     :: Walls
    , direction :: Direction
    , score     :: Score
    , gridSize  :: GridSize
    , isGameOver  :: Bool
    } deriving (Show, Eq)

-- exports

stepGame :: GameState -> GameState
stepGame state       
  | isGameOver state' = state'
  | otherwise         = moveStep . eatStep $ state'
  where state' = checkGameOver state

reactGame :: GameState -> Input -> GameState
reactGame state key = state { direction = changeDirection (direction state) key }

initGame :: GridSize -> GameState
initGame gs = GameState snake apples walls MoveRight 0 gs False
  where snake = MkSnake [(2,2)] False
        apples = Set.fromList [ (i,i) | i <- [5,8..40]]
        walls = Set.empty

snakePos :: (Int, Int)
snakePos = (10,10)

snakeBody :: GameState -> [Pos]
snakeBody = body . snake

-- helpers

moveStep :: GameState -> GameState
moveStep state = state { snake = moveSnake state }

moveSnake :: GameState -> Snake
moveSnake state = s { body = newHead : newTail, isGrowing = False }
  where newHead = nextPos state
        newTail = if isGrowing s then body s else removeTail s
        s       = snake state

nextPos :: GameState -> Pos
nextPos state = move (gridSize state) (direction state) (snakeHead . snake $ state)

eatStep :: GameState -> GameState
eatStep state = if Set.member next apls
                then state { snake = grow s, apples = eat apls next }
                else state
                where s     = snake state 
                      next  = nextPos state
                      apls  = apples state

grow :: Snake -> Snake
grow s = s { isGrowing = True }

eat :: Apples -> Pos -> Apples
eat apples pos = Set.delete pos apples

checkGameOver :: GameState -> GameState
checkGameOver state = if willBiteItself state || willBiteWall state
                      then gameOver state
                      else state

gameOver :: GameState -> GameState
gameOver state = state { isGameOver = True }

willBiteItself :: GameState -> Bool
willBiteItself state = List.elem (nextPos state) (body . snake $ state)

willBiteWall :: GameState -> Bool
willBiteWall state = Set.member (nextPos state) (walls state)

wrap :: GridSize -> Pos -> Pos
wrap (w, h) (x, y) = (x `mod` w, y `mod` h)

move :: GridSize -> Direction -> Pos -> Pos
move gs MoveRight (x,y) = wrap gs (x+1, y)
move gs MoveLeft  (x,y) = wrap gs (x-1, y)
move gs MoveUp    (x,y) = wrap gs (x, y-1)
move gs MoveDown  (x,y) = wrap gs (x, y+1)

oppositeDirection :: Direction -> Direction
oppositeDirection MoveLeft  = MoveRight
oppositeDirection MoveRight = MoveLeft
oppositeDirection MoveUp    = MoveDown
oppositeDirection MoveDown  = MoveUp

inSameDirection :: Direction -> Input -> Bool
inSameDirection d k = d == inputToDirection k

inOppositeDirection :: Direction -> Input -> Bool
inOppositeDirection d k = inSameDirection (oppositeDirection d) k

inputToDirection :: Input -> Direction
inputToDirection KeyLeft  = MoveLeft
inputToDirection KeyRight = MoveRight
inputToDirection KeyUp    = MoveUp
inputToDirection KeyDown  = MoveDown

directionToInput :: Direction -> Input
directionToInput MoveLeft  = KeyLeft
directionToInput MoveRight = KeyRight
directionToInput MoveUp    = KeyUp
directionToInput MoveDown  = KeyDown

changeDirection :: Direction -> Input -> Direction
changeDirection move key
  | inSameDirection move key || 
    inOppositeDirection move key  = move
  | otherwise                     = inputToDirection key

snakeHead :: Snake -> Pos
snakeHead (MkSnake s _) = head s

snakeTail :: Snake -> [Pos]
snakeTail (MkSnake s _) = tail s

removeTail :: Snake -> [Pos]
removeTail (MkSnake s _) = take (length s - 1) $ s