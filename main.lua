Config = require("config")
require("board")
require("piece")

local selectedPiece = nil
local mandatoryPieces = {}
local multiCapturePiece = nil -- CORREÇÃO: Nome unificado (antes estava multiCapture)
local validMoves = {}         -- Certifique-se que esta variável existe no escopo
local winner = nil            -- numero de ganhador

function love.load()
	love.window.setTitle("CheckersLua")
	love.window.setMode(Config.SCREEN_WIDTH, Config.SCREEN_HEIGHT)
	Piece.loadAssets()

	Board.restart()
	Board.showBoard()
end

function love.mousepressed(x, y, button)
	if button == 1 then
		local col = math.floor(x / SQUARE_SIZE) + 1
		local row = math.floor(y / SQUARE_SIZE) + 1
		if row < 1 or row > ROWS or col < 1 or col > COLS then
			return
		end

		local peca = Board.getPiece(row, col)

		if not selectedPiece then
			-- Se estamos em multicapture, o jogador SÓ pode selecionar a peça que já moveu
			if multiCapturePiece then
				if row == multiCapturePiece.row and col == multiCapturePiece.col then
					selectedPiece = { row = row, col = col }
					validMoves = Board.getValidMoves(row, col, true) -- Força apenas capturas
				else
					print("Você deve continuar a captura com a mesma peça!")
					return
				end
			else
				-- Lógica normal de seleção
				mandatoryPieces = Board.getAllPossibleCaptures()

				if peca ~= 0 and peca.player == Board.currentPlayer then
					if #mandatoryPieces > 0 then
						local isMandatory = false
						for _, p in ipairs(mandatoryPieces) do
							if p.row == row and p.col == col then
								isMandatory = true
								break
							end
						end
						if not isMandatory then
							return
						end
					end
					selectedPiece = { row = row, col = col }
					validMoves = Board.getValidMoves(row, col, #mandatoryPieces > 0)
				end
			end
		else
			-- Tentar mover
			local moveFinal = nil
			for _, m in ipairs(validMoves) do
				if m.row == row and m.col == col then
					moveFinal = m
					break
				end
			end

			if moveFinal then
				local captures = Board.movePiece(selectedPiece.row, selectedPiece.col, row, col)

				-- Checar se pode continuar capturando
				local canStillCapture = false
				if captures then
					local nextMoves = Board.getValidMoves(row, col, true)
					for _, m in ipairs(nextMoves) do
						if m.isCapture then
							canStillCapture = true
							break
						end
					end
				end

				if canStillCapture then
					-- Mantém o turno e obriga a usar esta peça
					multiCapturePiece = { row = row, col = col }
					selectedPiece = nil
					validMoves = {}
					print("Capture novamente!")
				else
					-- Finaliza o turno normalmente
					multiCapturePiece = nil
					selectedPiece = nil
					validMoves = {}
					mandatoryPieces = {}
					Board.changeTurn()

					winner = Board.checkWinner()
				end
			else
				-- Se não clicou num movimento válido e não está em multicapture, permite trocar a peça
				if not multiCapturePiece then
					selectedPiece = nil
					validMoves = {}
					love.mousepressed(x, y, button) -- recursao, quando mudar de posicao ja entra selecionado
				end
			end
		end
	end
end

function love.keypressed(key)
	if key == "escape" then
		print("saiu")
		love.event.quit()
	elseif key == "r" then
		print("reiniciado")
		Board.restart()
		winner = nil
		selectedPiece = nil
		validMoves = {}
		multiCapturePiece = nil
	end
end

function love.draw()
	Board.drawSquares()
	Board.drawPieces()

	-- Desenha destaque da seleção
	if selectedPiece then
		love.graphics.setLineWidth(3)
		love.graphics.setColor(1, 1, 0)
		love.graphics.circle(
			"line",
			(selectedPiece.col - 1) * SQUARE_SIZE + SQUARE_SIZE / 2,
			(selectedPiece.row - 1) * SQUARE_SIZE + SQUARE_SIZE / 2,
			SQUARE_SIZE * 0.45
		)

		-- CORREÇÃO/ADICIONAL: Desenha os círculos de movimentos possíveis
		for _, m in ipairs(validMoves) do
			if m.isCapture then
				love.graphics.setColor(1, 0, 0, 0.6) -- Vermelho para captura
			else
				love.graphics.setColor(0, 1, 0, 0.6) -- Verde para normal
			end
			love.graphics.circle(
				"fill",
				(m.col - 1) * SQUARE_SIZE + SQUARE_SIZE / 2,
				(m.row - 1) * SQUARE_SIZE + SQUARE_SIZE / 2,
				SQUARE_SIZE * 0.2
			)
		end
	end

	-- Desenha as peças que SÃO OBRIGADAS a soprar (comer)
	if #mandatoryPieces > 0 then
		love.graphics.setLineWidth(2)
		love.graphics.setColor(1, 0, 0, 0.5)
		for _, p in ipairs(mandatoryPieces) do
			love.graphics.circle(
				"line",
				(p.col - 1) * SQUARE_SIZE + SQUARE_SIZE / 2,
				(p.row - 1) * SQUARE_SIZE + SQUARE_SIZE / 2,
				SQUARE_SIZE * 0.5
			)
		end
	end

	-- Tela de Fim de Jogo
	if winner then
		-- Fundo semi-transparente
		love.graphics.setColor(0, 0, 0, 0.75)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

		-- Texto de Vitória
		love.graphics.setColor(1, 1, 1)
		local font = love.graphics.getFont()
		local texto = "Jogador " .. winner .. " Venceu!"
		local texto2 = "Pressione 'R' para reiniciar"

		-- Centraliza o texto na tela
		love.graphics.print(
			texto,
			love.graphics.getWidth() / 2 - font:getWidth(texto) / 2,
			love.graphics.getHeight() / 2 - 20
		)
		love.graphics.print(
			texto2,
			love.graphics.getWidth() / 2 - font:getWidth(texto2) / 2,
			love.graphics.getHeight() / 2 + 20
		)
	end
end
