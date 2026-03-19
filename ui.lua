UI = {}
UI.buttons = {}

function UI.newButton(label, x, y, width, height, onClick)
    local button = {
        label = label,
        x = x,
        y = y,
        width = width,
        height = height,
        isHovered = false,
        onClick = onClick
    }
    table.insert(UI.buttons, button)
end

function UI.clear()
    UI.buttons = {}
end

function UI.update(dt)
    -- posicao do mouse
    local mx, my = love.mouse.getPosition()
    for _, button in ipairs(UI.buttons) do
        --verifica se esta encima de algum botao
        button.isHovered = mx > button.x and mx < button.x + button.width and my > button.y and
        my < button.y + button.height
    end
end

function UI.draw()
    local font = love.graphics.getFont()

    for _, btn in ipairs(UI.buttons) do
        -- muda a cor do botao se estiver em cima
        love.graphics.setColor(btn.isHovered and { 0.4, 0.4, 0.4 } or { 0.2, 0.2, 0.2 })
        -- desenha retanculo do botao
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
        -- desenha o texto do botao centralizado
        love.graphics.setColor(1, 1, 1)
        local textW = font:getWidth(btn.label)
        local textH = font:getHeight()
        love.graphics.print(btn.label, btn.x + btn.width / 2 - textW / 2, btn.y + btn.height / 2 - textH / 2)
    end
end

function UI.mousepressed(x, y, button)
    if button == 1 then -- mouse left
        for _, btn in ipairs(UI.buttons) do
            if btn.isHovered and btn.onClick then
                -- excutar funcao atribuida ao botao
                btn.onClick()
            end
        end
        --
    end
end

return UI
