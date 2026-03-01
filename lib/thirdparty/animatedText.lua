--Animated Text API v0.1.0 (docs added by Snowy)
---@class AnimatedText
local api = {}
---@type AnimatedTextTask[]
local tasks = {}

---@param tbl AnimatedTextCharacters
local function trueLength(tbl)
	local length, _tbl = 0, {}
	for k, v in pairs(tbl) do
		for i = 1, #v.chars do
			if #v.chars[i] <= 1 then
				length = length + client.getTextWidth(v.chars[i])
			else
				length = length + 8
			end
			if v.chars[i] == "\n" or i == #v.chars and k >= #tbl then
				table.insert(_tbl, length)
				length = 0
			end
		end
	end
	return _tbl
end

---@param char string
local function trueCharWidth(char)
	if #char <= 1 or char == "\n" then return client.getTextWidth(char) else return 8 end
end

---@param str string
---@return AnimatedTextCharacters[]
local function deconstructString(str)
	local match = "[\x00-\x7F\xC2-\xF4][\x80-\xBF]*"
	local tbl, i, lastCapture, capturing = {}, 1, 1, false
	for char in str:gmatch(match) do
		local substring = str:sub(lastCapture, i)
		if char == ":" then
			if capturing then table.insert(tbl, substring) end
			if not capturing and i == #str then table.insert(tbl, char) end
			capturing, lastCapture = not capturing, i
		elseif capturing and char:match("[%s]") or capturing and i == #str then
			for _char in substring:gmatch(match) do table.insert(tbl, _char) end
			capturing = false
		elseif not capturing then
			table.insert(tbl, char)
		end
		i = i + #char
	end
	return tbl
end

---@param json table
---@param _tbl table?
---@return AnimatedTextCharacters[]
local function deconstructJson(json, _tbl)
	local tbl = _tbl or {}
	---@class AnimatedTextCharacters
	---@field chars string[]
	---@field properties table
	local charTbl = { chars = {}, properties = {} }
	for k, v in pairs(json) do
		if type(v) ~= "table" then
			if k == "text" then
				charTbl.chars = deconstructString(v)
			else
				charTbl.properties[k] = v
			end
		else
			deconstructJson(v, tbl)
		end
	end
	if json.text then table.insert(tbl, charTbl) end
	return tbl
end

---@param task AnimatedTextTask
---@param _text string|table
local function createTasks(task, _text)
	local text = type(_text) == "table" and deconstructJson(_text) or
	deconstructString(_text) ---@diagnostic disable-line: param-type-mismatch
	local span, length, line = 0, trueLength(text), 1
	for _, v in pairs(text) do
		for _, char in pairs(v.chars) do
			if char == "\n" then span, line = 0, line + 1 end
			table.insert(task.textTasks, {
				anchor = vec(
					(span - length[line] / 2) * -task.scale.x,
					(line - 1) * -task.scale.y * client.getTextHeight(""),
					0
				) + task.offset,
				task = task.root:newText(#task.textTasks), ---@diagnostic disable-line: param-type-mismatch
			})
			local textTask, _json = task.textTasks[#task.textTasks], { text = char }
			for k, v in pairs(v.properties) do _json[k] = v end ---@diagnostic disable-line: redefined-local
			textTask.task:pos(textTask.anchor)
				:scale(task.scale)
				:setAlignment("LEFT")
				:text(v.properties and toJson(_json) or char)
			span = span + trueCharWidth(char)
		end
	end
end

---@param name string
function api.remove(name)
	for _, v in pairs(tasks[name].root:getTask()) do v:remove() end
end

---@param name string
---@param parent ModelPart
---@param offset Vector3
---@param scale Vector3
---@param parentType ModelPart.parentType
---@param json string|table
function api.new(name, parent, offset, scale, parentType, json)
	if tasks[name] then api.remove(name) end
	---@class AnimatedTextTask
	tasks[name] = {
		offset = offset,
		scale = scale,
		root = parent:newPart(name):setParentType(
			parentType),
		textTasks = {}
	}
	if json then createTasks(tasks[name], json) end
end

---@param name string
---@param json string|table
function api.setText(name, json)
	if tasks[name].textTasks then api.remove(name) end
	createTasks(tasks[name], json)
end

---@param name string
---@return AnimatedTextTask
function api.getTask(name) return tasks[name] end

---@param name string
---@param pos Vector3?
---@param rot Vector3?
---@param scale Vector3?
---@param char table
function api.transform(name, pos, rot, scale, char)
	char.task:pos(char.anchor + (pos or vec(0, 0, 0)))
		:rot(rot or vec(0, 0, 0))
		:scale(tasks[name].scale + (scale or vec(0, 0, 0)))
end

return api
