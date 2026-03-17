local Piece = {}
Piece.__index = Piece

function Piece.new(player, row, col)
  local self = setmetatable({}, Piece)
  self.player = player
  self.row = row
  self.col = col
  self.isKing = false
  return self
end

function Piece:getDirections()
  -- h: sempre move para esquerda (-1) e direita (1)
  local h = { 1, -1 }

  -- v: define se vai para baixo (1) ou para cima (-1)
  local v = { self.player == 1 and 1 or -1 }

  -- Se for Dama, libera o eixo V para os dois lados
  if self.isKing then
    v = { 1, -1 }
  end

  -- Monta a lista final combinando V e H para o board.lua usar
  local dirs = {}
  for _, dv in ipairs(v) do
    for _, dh in ipairs(h) do
      table.insert(dirs, { dv, dh })
    end
  end

  return dirs
end

function Piece:promote()
  self.isKing = true
  print("Peça promovida a Dama!")
end

return Piece
