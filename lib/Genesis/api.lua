local functions = require('lib.Genesis.functions')

local api = {}

api.log_chat_to_file = function(file_path, player_name, message)
    local file = io.open(file_path, "a")
    if file then
        file:write("[" .. os.date("%d.%m.%Y %X") .. "] " .. player_name .. ": " .. message .. "\n")
        file:flush()
        file:close()
    end
end

api.kick_if_prohibited_characters = function(player_name, message, debug_file_path, blacklist)
    if functions.contains_prohibited_characters(message, blacklist) then
        for _, pid in ipairs(players.list(true, true, true)) do
            if players.get_name(pid) == player_name then
                menu.trigger_commands("kick " .. player_name)
                functions.log_debug("Player kicked for prohibited characters: " .. player_name, debug_file_path)
                util.toast("Player kicked for prohibited characters: " .. player_name)
                break
            end
        end
    end
end

return api
