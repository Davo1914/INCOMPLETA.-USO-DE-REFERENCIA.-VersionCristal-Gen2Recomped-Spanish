-- VersiónCristal: Pokemon Crystal en español de España.
--
-- Los nombres de los movimientos y de los Pokemon se mantienen
-- deliberadamente en inglés:
-- no hay lang/move_names.lua ni lang/species_names.lua en este mod.

return function(mod)
  local function catalog(name)
    local rel = "lang/" .. name .. ".lua"
    local body = mod:read(rel)
    if not body then return {} end
    local loader = loadstring or load
    local chunk, err = loader(body, rel)
    if not chunk then
      mod.log:warn("%s tem erro de sintaxe: %s", rel, tostring(err))
      return {}
    end
    local ok, t = pcall(chunk)
    if not ok or type(t) ~= "table" then
      mod.log:warn("%s nao devolveu uma tabela", rel)
      return {}
    end
    return t
  end

  local function each(name, apply)
    local n = 0
    for k, v in pairs(catalog(name)) do
      if type(v) == "string" and v ~= "" then
        apply(k, v)
        n = n + 1
      end
    end
    return n
  end

  -- ---- glifos -------------------------------------------------------
  -- Registrar ANTES de que cualquier elemento solicite un glifo. La ruta de la imagen
  -- se pasa directamente a love.graphics.newImage, que la resuelve desde la raíz del
  -- juego y no desde el mod; sin `mod.assets:path`, la página se carga vacía
  -- y todos los caracteres acentuados se muestran en blanco.
  for id, page in pairs(catalog("font")) do
    if type(page) == "table" and type(page.image) == "string"
        and mod:read(page.image) then
      page.image = mod.assets:path(page.image)
    end
    mod.content.font:register(id, page)
  end
  for seq, code in pairs(catalog("charmap")) do
    mod.content.font:register("charmap:" .. seq, { seq = seq, code = code })
  end

  -- ---- aplicación -----------------------------------------------------
  -- Clave = etiqueta con nombre del desmontaje o TEXT_S<banco>_<endereco>
  -- cuando el extractor no resuelve la etiqueta. Es el formato de Gen2Recomped;
  -- este mod no funciona en gen1recomp (que no admite Crystal e indexa mediante
  -- el puntero "banco:endereco").
  local n = 0
  n = n + each("dialogue", function(k, v)
    mod.content.text:override(k, v)
  end)
  n = n + each("strings", function(src, value)
    mod.content.strings:override(src, value)
  end)
  n = n + each("item_names", function(id, value)
    mod.content.items:patch(id, { name = value })
  end)
  -- El estado tiene dos etiquetas: la del texto y la de tres letras que cabe en la
  -- casilla situada junto a la barra de vida. Cambiar solo la primera dejaría el HUD
  -- en inglés, precisamente donde más aparece la etiqueta.
  n = n + each("status_labels", function(id, value)
    mod.content.statuses:patch(id, { label = value, hudLabel = value })
  end)
  -- Descripción del objeto. `description` no está declarado en el esquema, pero el
  -- registro de nivel superior es extensible y el código que dibuja la interfaz lee `def.description`.
  -- `pcall` aísla el proceso: si la ruta no existe, el mod sigue funcionando y el aviso
  -- aparece en el registro en lugar de provocar un fallo general.
  local descOk, descErro = 0, nil
  each("item_descriptions", function(id, value)
    local ok, err = pcall(function()
      mod.content.items:patch(id, { description = value })
    end)
    if ok then descOk = descOk + 1 elseif not descErro then descErro = err end
  end)
  n = n + descOk
  if descErro then
    mod.log:warn("descripcion de item no aplicada: %s", tostring(descErro))
  end
  -- Descripción de movimiento.  Aparece en la pantalla de resumen del POKéMON y en la bolsa
  -- cuando el item es una TM o HM -- allí el juego muestra la descripción del MOVIMIENTO.
  local mvOk, mvErro = 0, nil
  each("move_descriptions", function(id, value)
    local ok, err = pcall(function()
      mod.content.moves:patch(id, { description = value })
    end)
    if ok then mvOk = mvOk + 1 elseif not mvErro then mvErro = err end
  end)
  n = n + mvOk
  if mvErro then
    mod.log:warn("descripcion de movimiento no aplicada: %s", tostring(mvErro))
  end

  mod.events:on("game.ready", function()
    mod.log:info("VersaoCristal: %d textos aplicados", n)
  end)
end
