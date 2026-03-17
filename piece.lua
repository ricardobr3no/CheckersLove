local Piece = {}
Piece.__index = Piece

function Piece.new(player, row, col)
  local self = setmetatable({}, Piece)
  self.player = player -- 1 ou 2
  self.row = row
  self.col = col
  self.isKing = false -- Começa como peça normal
  return self
end

-- Retorna as direções que a peça pode se mover
function Piece:getDirections()
  if self.isKing then
    -- Damas movem em todas as 4 direções
    return { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
  end

  -- Peças normais respeitam a direção do jogador
  if self.player == 1 then
    return { { 1, 1 }, { 1, -1 } } -- Desce
  else
    return { { -1, 1 }, { -1, -1 } } -- Sobe
  end
end

-- Método para promover a peça
function Piece:promote()
  self.isKing = true
  print("Peça promovida a Dama!")
end

return Piece
