Config = require("config") -- Certifique-se que SCREEN_SIZE está definido lá
Piece = require("piece")

ROWS, COLS = 8, 8
SQUARE_SIZE = Config.BOARD_SIZE / 8

local function createBoard()
	local board = {}
	for row = 1, ROWS do
		board[row] = {}
		for col = 1, COLS do
			board[row][col] = 0
		end
	end

	for row = 1, ROWS do
		for col = 1, COLS do
			if (row + col) % 2 == 1 then
				if row <= 3 then
					board[row][col] = Piece.new(1, row, col) -- Jogador 1
				elseif row >= 6 then
					board[row][col] = Piece.new(2, row, col) -- CORREÇÃO: Jogador 2 também é objeto
				end
			end
		end
	end
	return board
end

Board = { board = createBoard(), currentPlayer = 1 }

Board.drawSquares = function()
	for row = 1, ROWS do
		for col = 1, COLS do
			-- Lógica de cores do tabuleiro
			if (row + col) % 2 == 1 then
				love.graphics.setColor(0.2, 0.2, 0.2) -- Escuro
			else
				love.graphics.setColor(0.8, 0.8, 0.8) -- Claro
			end

			-- Desenha o quadrado (ajustando índice 1-based para posição 0-based)
			love.graphics.rectangle("fill", (col - 1) * SQUARE_SIZE, (row - 1) * SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE)
		end
	end
end

Board.canCapture = function(oldRow, oldCol, newRow, newCol)
	if math.abs(newRow - oldRow) == 2 and math.abs(newCol - oldCol) == 2 then
		local midRow = (newRow + oldRow) / 2
		local midCol = (newCol + oldCol) / 2
		local pecaMid = Board.getPiece(midRow, midCol)
		local pecaDest = Board.getPiece(newRow, newCol)

		-- CORREÇÃO: Acessar .player pois pecaMid é um objeto
		if pecaMid ~= 0 and pecaMid.player ~= Board.currentPlayer and pecaDest == 0 then
			return true, midRow, midCol
		end
	end
	return false
end

Board.movePiece = function(oldRow, oldCol, newRow, newCol)
	local peca = Board.getPiece(oldRow, oldCol)
	local isCapture, midRow, midCol = Board.canCapture(oldRow, oldCol, newRow, newCol)

	Board.board[oldRow][oldCol] = 0
	Board.board[newRow][newCol] = peca
	peca.row, peca.col = newRow, newCol -- Atualiza posição interna da peça

	if isCapture and midRow and midCol then
		Board.board[midRow][midCol] = 0
	end

	-- LÓGICA DE PROMOÇÃO:
	if (peca.player == 1 and newRow == ROWS) or (peca.player == 2 and newRow == 1) then
		peca:promote()
	end

	return isCapture
end

-- CORREÇÃO: Proteção para não dar erro de 'index nil'
Board.getPiece = function(row, col)
	if Board.board[row] then
		return Board.board[row][col]
	end
	return 0
end

Board.restart = function()
	Board.board = createBoard()
end

Board.showBoard = function()
	for row = 1, ROWS do
		for col = 1, COLS do
			local p = Board.board[row][col]
			-- CORREÇÃO: Verifica se é objeto para imprimir o player, senão imprime 0
			io.write((type(p) == "table" and p.player or p) .. ", ")
		end
		print()
	end
end

Board.drawPieces = function()
	for row = 1, ROWS do
		for col = 1, COLS do
			local piece = Board.getPiece(row, col)
			if piece ~= 0 then
				-- Calcula onde é o meio do quadrado
				local centerX = (col - 1) * SQUARE_SIZE + SQUARE_SIZE / 2
				local centerY = (row - 1) * SQUARE_SIZE + SQUARE_SIZE / 2

				-- Manda a peça desenhar-se a si mesma!
				piece:draw(centerX, centerY, SQUARE_SIZE)
			end
		end
	end
end

Board.changeTurn = function()
	if Board.currentPlayer == 1 then
		Board.currentPlayer = 2
	else
		Board.currentPlayer = 1
	end
	print("Vez do jogador " .. Board.currentPlayer)
end

Board.getAllPossibleCaptures = function()
	local mandatoryPieces = {}

	for r = 1, ROWS do
		for c = 1, COLS do
			local piece = Board.getPiece(r, c)
			if piece ~= 0 and piece.player == Board.currentPlayer then
				local moves = Board.getValidMoves(r, c, true)
				local hasCapture = false
				for _, m in ipairs(moves) do
					if m.isCapture then
						hasCapture = true
						break
					end
				end

				if hasCapture then
					table.insert(mandatoryPieces, { row = r, col = c })
				end
			end
		end
	end
	return mandatoryPieces
end
-- Agora passamos 'onlyCaptures' como opcional para evitar recursão infinita
Board.getValidMoves = function(row, col, onlyCaptures)
	local piece = Board.getPiece(row, col)
	if piece == 0 then
		return {}
	end

	local captureMoves = {}
	local normalMoves = {}

	local dirs = piece:getDirections()

	-- 1. Checa as capturas nas direções permitidas
	for _, dir in ipairs(dirs) do
		local r2, c2 = row + (dir[1] * 2), col + (dir[2] * 2)
		if r2 >= 1 and r2 <= ROWS and c2 >= 1 and c2 <= COLS then
			local isCap, _, _ = Board.canCapture(row, col, r2, c2)
			if isCap then
				table.insert(captureMoves, { row = r2, col = c2, isCapture = true })
			end
		end
	end

	if #captureMoves > 0 then
		return captureMoves
	end
	if onlyCaptures then
		return {}
	end

	-- 2. Checa os movimentos normais nas direções permitidas
	for _, dir in ipairs(dirs) do
		local r1, c1 = row + dir[1], col + dir[2]
		if r1 >= 1 and r1 <= ROWS and c1 >= 1 and c1 <= COLS then
			if Board.getPiece(r1, c1) == 0 then
				table.insert(normalMoves, { row = r1, col = c1, isCapture = false })
			end
		end
	end

	return normalMoves
end

function Board.checkWinner()
	local countCurrentPlayerPieces = 0
	local currentPlayerHasMoves = false

	for row = 1, ROWS do
		for col = 1, COLS do
			local piece = Board.getPiece(row, col)
			-- verificar as pecas do jogador atual
			if piece ~= 0 and piece.player == Board.currentPlayer then
				countCurrentPlayerPieces = countCurrentPlayerPieces + 1
				-- se ele tiver ao menos UM movimento valido ainda esta no jogo
				local validMoves = Board.getValidMoves(row, col, false)
				if #validMoves > 0 then
					currentPlayerHasMoves = true
				end
			end
		end
	end

	-- se o jogador atual nao tem pecas ou movimentos, o OUTRO jogador vence
	if countCurrentPlayerPieces == 0 or not currentPlayerHasMoves then
		-- returna numero do ganhador
		return Board.currentPlayer == 1 and 2 or 1
	end

	return nil -- continua o jogo
end

return Board
