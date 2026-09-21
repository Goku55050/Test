


if getgenv().Loaded then return end
getgenv().Loaded = true




do
    local _p  = game:GetService("Players").LocalPlayer
    local _bannedIds  = { [10497392350] = true, [9685313117] = true }
    local _bannedHwids = {
        ["42d7c5174c6b0bf2ac16435f26dff970eeb59bb749585c9f332bbe1be56d3b22"] = true,
    }

    
    local _uid = _p and _p.UserId
    if _uid and _bannedIds[_uid] then
        _p:Kick("You are permanently banned from Ares Chat.")
        return
    end

    
    local _hwid = ""
    if gethwid        then local ok,h = pcall(gethwid)        if ok and type(h)=="string" then _hwid=h:lower():gsub("%s+","") end end
    if _hwid=="" and getmacaddress then local ok,h = pcall(getmacaddress) if ok and type(h)=="string" then _hwid=h:lower():gsub("%s+","") end end
    if _hwid=="" and getdeviceid   then local ok,h = pcall(getdeviceid)   if ok and type(h)=="string" then _hwid=h:lower():gsub("%s+","") end end
    if _hwid ~= "" and _bannedHwids[_hwid] then
        _p:Kick("You are permanently banned from Ares Chat.")
        return
    end
end



local safeRequestFn

if not getgenv()._AresAntiSpyInstalled then
getgenv()._AresAntiSpyInstalled = true

local HttpService = game:GetService("HttpService")

local detected = false

local ts = game:GetService("TweenService")

function log(msg)
    warn("[ANTI-SPY] "..msg)
end

local deb = false

function punishment()
    if not deb then deb = true else return end
    pcall(function()
        game:GetService("Players").LocalPlayer:Kick("BETA ! , ARES PAPA SE HOSIYARI? \240\159\164\163")
    end)
end

local realHookFunction = clonefunction(hookfunction)
local realHookMetamethod = clonefunction(hookmetamethod)

local originals = {}
local HTTP_METHODS = {
    HttpGet = true,
    HttpPost = true,
    GetAsync = true,
    PostAsync = true,
    RequestAsync = true,
}

function deepCollect(fn,visited,depth)
    local found = {}
    if depth > 6 or not fn or type(fn) ~= "function" then return found end
    if visited[fn] then return found end
    visited[fn] = true

    local function process(v)
        if type(v) == "function" then
            found[v] = true
            for f in pairs(deepCollect(v,visited,depth + 1)) do
                found[f] = true
            end
        elseif type(v) == "table" and depth < 4 then
            for i,tv in pairs(v) do
                if type(tv) == "function" then
                    found[tv] = true
                    for f in pairs(deepCollect(tv,visited,depth + 2)) do
                        found[f] = true
                    end
                end
            end
        end
    end

    pcall(function()
        local ups = getupvalues(fn)
        if ups then for i,v in pairs(ups) do process(v) end end
    end)

    pcall(function()
        for i = 1,50 do
            local a,b = getupvalue(fn,i)
            if a == nil and b == nil then break end
            process(a)
            if b ~= nil then process(b) end
        end
    end)

    pcall(function()
        for i = 1,50 do
            local name,val = debug.getupvalue(fn,i)
            if not name then break end
            process(val)
        end
    end)

    return found
end

function recoverOriginal(fn,name)
    if not fn then return nil,false end

    local hooked = false

    if islclosure(fn) then
        hooked = true
        log("Detected L closure hook on "..name)
    end

    local restored
    pcall(function() restored = getoriginalfunction(fn) end)
    if restored and type(restored) == "function" and iscclosure(restored) then
        if hooked then log("Recovered "..name.." via getoriginalfunction") end
        pcall(function() realHookFunction(fn,restored) end)
        return restored,hooked
    end

    local dummy = newcclosure(function() end)
    local prev
    pcall(function() prev = realHookFunction(fn,dummy) end)

    if not prev then
        pcall(function() realHookFunction(fn,fn) end)
        local fb
        pcall(function() fb = clonefunction(fn) end)
        return fb,hooked
    end

    if islclosure(prev) then
        hooked = true
        log("Detected hook on "..name.." (L closure from hookfunction)")

        local allFns = deepCollect(prev,{},0)
        for f in pairs(allFns) do
            if iscclosure(f) then
                log("Recovered "..name.." from spy upvalues")
                realHookFunction(fn,f)
                return f,true
            end
        end

        local cl
        pcall(function() cl = clonefunction(prev) end)
        if cl and iscclosure(cl) then
            realHookFunction(fn,cl)
            return cl,true
        end

        realHookFunction(fn,prev)
        local fb
        pcall(function() fb = clonefunction(fn) end)
        return fb or prev,true
    end

    realHookFunction(fn,prev)
    return prev,hooked
end

local anyHooked = false

local instanceMethods = {
    {game.HttpGet,"HttpGet","game.HttpGet"},
    {game.HttpPost,"HttpPost","game.HttpPost"},
    {HttpService.GetAsync,"GetAsync","HttpService.GetAsync"},
    {HttpService.PostAsync,"PostAsync","HttpService.PostAsync"},
    {HttpService.RequestAsync,"RequestAsync","HttpService.RequestAsync"},
}

for i,m in ipairs(instanceMethods) do
    local orig,hooked = recoverOriginal(m[1],m[3])
    originals[m[2]] = orig
    if hooked then anyHooked = true end
end

local globalFns = {
    {request,"request","request"},
    {http_request,"http_request","http_request"},
    {http and http.request,"http_dot_request","http.request"},
    {syn and syn.request,"syn_request","syn.request"},
}

for i,g in ipairs(globalFns) do
    if g[1] then
        local orig,hooked = recoverOriginal(g[1],g[3])
        originals[g[2]] = orig
        if hooked then anyHooked = true end
    end
end

pcall(function() if originals.request and request then getgenv().request = originals.request end end)
pcall(function() if originals.http_request and http_request then getgenv().http_request = originals.http_request end end)
pcall(function() if originals.http_dot_request and http then http.request = originals.http_dot_request end end)
pcall(function() if originals.syn_request and syn then syn.request = originals.syn_request end end)

local rawMt
pcall(function() rawMt = getrawmetatable(game) end)

local originalNc

local ncDummy = newcclosure(function(self,...) return nil end)
local prevNc
pcall(function() prevNc = realHookMetamethod(game,"__namecall",ncDummy) end)

if prevNc then
    if islclosure(prevNc) then
        anyHooked = true
        log("Detected spy hook on __namecall")

        local allFns = deepCollect(prevNc,{},0)
        for f in pairs(allFns) do
            if iscclosure(f) then
                originalNc = f
                log("Recovered original __namecall from spy upvalues")
                break
            end
        end

        if not originalNc then
            pcall(function() originalNc = clonefunction(prevNc) end)
            if not originalNc then originalNc = prevNc end
        end
    else
        originalNc = prevNc
    end
else
    pcall(function() originalNc = rawMt.__namecall end)
end

if anyHooked then
    detected = true
    log("HTTP SPY DETECTED - hooks neutralized")
    punishment()
end


function cleanupSpyData()
        pcall(function()
                for i,obj in pairs(getgc(true)) do
                        if type(obj) == "table" then
                                pcall(function()
                                        local first = rawget(obj,1)
                                        if type(first) == "table" then
                                                local url = rawget(first,"Url") or rawget(first,"url")
                                                local method = rawget(first,"Method") or rawget(first,"method")
                                                if type(url) == "string" and type(method) == "string" then
                                                        for i = #obj,1,-1 do rawset(obj,i,nil) end
                                                end
                                        end
                                end)
                        end
                end
        end)
end

cleanupSpyData()

local ncHandler 



task.spawn(function()
    while task.wait(2) do
        pcall(function()
            
            local recheck = {
                {game.HttpGet,          "HttpGet",          "game.HttpGet"},
                {game.HttpPost,         "HttpPost",         "game.HttpPost"},
                {HttpService.GetAsync,  "GetAsync",         "HttpService.GetAsync"},
                {HttpService.PostAsync, "PostAsync",        "HttpService.PostAsync"},
                {HttpService.RequestAsync,"RequestAsync",   "HttpService.RequestAsync"},
            }
            for _, m in ipairs(recheck) do
                local fn = m[1]
                if fn and islclosure(fn) then
                    log("Re-hook detected on "..m[3].." \226\128\148 recovering")
                    local orig, _ = recoverOriginal(fn, m[3])
                    if orig then originals[m[2]] = orig end
                    detected = true
                    punishment()
                end
            end
            
            local gcheck = {
                {request,                        "request",          "request"},
                {http_request,                   "http_request",     "http_request"},
                {http and http.request or nil,   "http_dot_request", "http.request"},
                {syn and syn.request or nil,     "syn_request",      "syn.request"},
            }
            for _, g in ipairs(gcheck) do
                local fn = g[1]
                if fn and islclosure(fn) then
                    log("Re-hook detected on "..g[3].." \226\128\148 recovering")
                    local orig, _ = recoverOriginal(fn, g[3])
                    if orig then originals[g[2]] = orig end
                    detected = true
                    punishment()
                end
            end
            
            pcall(function()
                local mt = getrawmetatable(game)
                if mt and rawget(mt, "__namecall") ~= ncHandler then
                    setreadonly(mt, false)
                    mt.__namecall = ncHandler
                    setreadonly(mt, true)
                    log("__namecall re-hook detected \226\128\148 restored")
                    detected = true
                    punishment()
                end
            end)
        end)
    end
end)

ncHandler = newcclosure(function(self,...)
    local method = getnamecallmethod()
    if HTTP_METHODS[method] and originals[method] then
        return originals[method](self,...)
    end
    if originalNc then
        return originalNc(self,...)
    end
end)

pcall(function() realHookMetamethod(game,"__namecall",ncHandler) end)

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt,false)
    mt.__namecall = ncHandler
    setreadonly(mt,true)
end)

function restoreAll()
    log("Restoring original functions...")

    pcall(function() if originals.HttpGet then realHookFunction(game.HttpGet,originals.HttpGet) end end)
    pcall(function() if originals.HttpPost then realHookFunction(game.HttpPost,originals.HttpPost) end end)
    pcall(function() if originals.GetAsync then realHookFunction(HttpService.GetAsync,originals.GetAsync) end end)
    pcall(function() if originals.PostAsync then realHookFunction(HttpService.PostAsync,originals.PostAsync) end end)
    pcall(function() if originals.RequestAsync then realHookFunction(HttpService.RequestAsync,originals.RequestAsync) end end)

    pcall(function() if originals.request and request then realHookFunction(request,originals.request) end end)
    pcall(function() if originals.http_request and http_request then realHookFunction(http_request,originals.http_request) end end)
    pcall(function() if originals.http_dot_request and http and http.request then realHookFunction(http.request,originals.http_dot_request) end end)
    pcall(function() if originals.syn_request and syn and syn.request then realHookFunction(syn.request,originals.syn_request) end end)

    log("All functions restored.")
end


function isProtectedFunction(fn)
    if not fn or type(fn) ~= "function" then return false end
    if fn == game.HttpGet or fn == game.HttpPost then return true end
    if fn == HttpService.GetAsync or fn == HttpService.PostAsync or fn == HttpService.RequestAsync then return true end
    if request and fn == request then return true end
    if http_request and fn == http_request then return true end
    if http and http.request and fn == http.request then return true end
    if syn and syn.request and fn == syn.request then return true end
    return false
end

realHookFunction(hookfunction,newcclosure(function(target,hook)
    if isProtectedFunction(target) then
        log("BLOCKED hookfunction attempt on HTTP function")
        detected = true
        punishment()
        return target
    end
    return realHookFunction(target,hook)
end))

realHookFunction(hookmetamethod,newcclosure(function(obj,method,hook)
    if obj == game and method == "__namecall" and type(hook) == "function" then
        local actualHook = hook
        return realHookMetamethod(obj,method,newcclosure(function(self,...)
            local m = getnamecallmethod()
            if HTTP_METHODS[m] and originals[m] then
                return originals[m](self,...)
            end
            return actualHook(self,...)
        end))
    end
    return realHookMetamethod(obj,method,hook)
end))


safeRequestFn = originals.request or originals.http_request or originals.syn_request or originals.http_dot_request

function safePost(url,body,headers)
    if not safeRequestFn then
        warn("[ANTI-SPY] No safe request function available")
        return nil,0
    end
    headers = headers or {["Content-Type"] = "application/json"}
    local ok,response = pcall(safeRequestFn,{
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body,
    })
    if ok and response then return response.Body,response.StatusCode end
    warn("[ANTI-SPY] safePost failed : "..tostring(response))
    return nil,0
end

function safeGet(url,headers)
    if not safeRequestFn then return nil,0 end
    headers = headers or {}
    local ok,response = pcall(safeRequestFn,{
        Url = url,
        Method = "GET",
        Headers = headers,
    })
    if ok and response then return response.Body,response.StatusCode end
    return nil,0
end

getgenv().safePost = safePost
getgenv().safeGet = safeGet

getgenv().safeGet("https://httpbin.org/get")

log("[ANTI-SPY] Loaded")

end 



if not getgenv().safePost then
    local _fb = request or http_request or (http and http.request) or (syn and syn.request)
    getgenv().safePost = function(url, body, headers)
        headers = headers or {["Content-Type"] = "application/json"}
        local ok, res = pcall(_fb, {Url=url, Method="POST", Headers=headers, Body=body})
        if ok and res then return res.Body, res.StatusCode end
        return nil, 0
    end
    getgenv().safeGet = function(url, headers)
        local ok, res = pcall(_fb, {Url=url, Method="GET", Headers=headers or {}})
        if ok and res then return res.Body, res.StatusCode end
        return nil, 0
    end
    safeRequestFn = _fb  
end
safePost = getgenv().safePost
safeGet  = getgenv().safeGet

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local TeleportService = game:GetService("TeleportService")
local SocialService = game:GetService("SocialService")
local LocalPlayer = Players.LocalPlayer
local JobId = game.JobId

local function _getUpval(fn, i)

    if debug and debug.getupvalue then
        local ok, a, b = pcall(debug.getupvalue, fn, i)
        if ok then
            if type(a) == "string" then return true, b   end
            if a ~= nil           then return true, a   end
        end
    end

    if getupvalue then
        local ok, a, b = pcall(getupvalue, fn, i)
        if ok then
            if type(a) == "string" then return true, b   end
            if a ~= nil           then return true, a   end
        end
    end
    return false, nil
end

local function _setUpval(fn, i, newVal)
    if debug and debug.setupvalue then
        pcall(debug.setupvalue, fn, i, newVal)
    end
    if setupvalue then
        pcall(setupvalue, fn, i, newVal)
    end
end

local function _extractOrigIndex(fn)
    if not fn then return nil end

    if getupvalues then
        local ok, uvs = pcall(getupvalues, fn)
        if ok and type(uvs) == "table" then
            for _, v in pairs(uvs) do
                if type(v) == "function" then return v end
            end
        end
    end

    for i = 1, 200 do
        local found, val = _getUpval(fn, i)
        if not found then break end
        if type(val) == "function" then return val end
    end

    return nil
end

local function _neutralizeHook(fn)
    if not fn then return end

    if getupvalues and setupvalues then
        local ok, uvs = pcall(getupvalues, fn)
        if ok and type(uvs) == "table" then
            local patch = {}
            for k, v in pairs(uvs) do
                if type(v) == "boolean" then patch[k] = false end
            end
            pcall(setupvalues, fn, patch)
        end
    end

    for i = 1, 200 do
        local found, val = _getUpval(fn, i)
        if not found then break end
        if type(val) == "boolean" then
            _setUpval(fn, i, false)
        end
    end
end

local _origIndex = nil

pcall(function()
    local mt  = getrawmetatable(game)
    local idx = rawget(mt, "__index")
    if type(idx) == "function" then
        local orig = _extractOrigIndex(idx)

        if orig then
            local ok, testVal = pcall(orig, game, "PlaceId")
            if ok and type(testVal) == "number" then
                _origIndex = orig
            end
        end
    end
end)

local function _readReal(prop)

    if cloneref then
        local ok, val = pcall(function()
            return cloneref(LocalPlayer)[prop]
        end)
        if ok and val ~= nil then return val end
    end

    if _origIndex then
        local ok, val = pcall(_origIndex, LocalPlayer, prop)
        if ok and val ~= nil then return val end
    end

    if prop == "Name" then
        local ok, val = pcall(function()
            return LocalPlayer:GetFullName():match("Players%.(.+)")
        end)
        if ok and val and val ~= "" then return val end
    end

    local ok, val = pcall(function() return LocalPlayer[prop] end)
    if ok then return val end
    return nil
end

local RealName        = tostring(_readReal("Name") or "")
local RealDisplayName = tostring(_readReal("DisplayName") or RealName)
local RealUserId      = _readReal("UserId")

pcall(function()
    local n = LocalPlayer:GetFullName():match("Players%.(.+)")
    if n and n ~= "" then RealName = n end
end)

local _hookedName = ""
pcall(function() _hookedName = tostring(LocalPlayer.Name) end)
local _nameHooked = (_hookedName ~= RealName)

if _nameHooked then
    RealDisplayName = RealName
end

task.spawn(function()
    pcall(function()

        local ok, uid = pcall(function()
            return Players:GetUserIdFromNameAsync(RealName)
        end)
        if ok and type(uid) == "number" and uid > 0 then
            RealUserId = uid
        end

        if not _nameHooked then
            local dn = tostring(_readReal("DisplayName") or "")
            if dn ~= "" then RealDisplayName = dn end
        end

        if BANNED_IDS and BANNED_IDS[RealUserId] then
            isKickedOrBanned = true
            LocalPlayer:Kick("You are permanently banned from Ares Chat.")
        end
    end)
end)

task.spawn(function()
    pcall(function()
        local mt  = getrawmetatable(game)
        if not mt then return end
        local idx = rawget(mt, "__index")
        if type(idx) ~= "function" then return end
        _neutralizeHook(idx)
    end)
end)

task.spawn(function()
    while task.wait(5) do
        pcall(function()

            local mt  = getrawmetatable(game)
            if mt then
                local idx = rawget(mt, "__index")
                if type(idx) == "function" then

                    _neutralizeHook(idx)

                    local orig = _extractOrigIndex(idx)
                    if orig then
                        local ok, testVal = pcall(orig, game, "PlaceId")
                        if ok and type(testVal) == "number" then
                            _origIndex = orig
                        end
                    end
                end
            end

            local fp = LocalPlayer:GetFullName()
            local fn = fp and fp:match("Players%.(.+)")
            if fn and fn ~= "" then RealName = fn end

            local freshUid = _readReal("UserId")
            if freshUid and type(freshUid) == "number" and freshUid > 0 then
                RealUserId = freshUid
            end

            local luaName = ""
            pcall(function() luaName = tostring(LocalPlayer.Name) end)
            if luaName ~= RealName then

                RealDisplayName = RealName
            else
                local dn = tostring(_readReal("DisplayName") or "")
                if dn ~= "" then RealDisplayName = dn end
            end
        end)
    end
end)

local DATABASE_URL        = "https://ares-chat-f7794-default-rtdb.firebaseio.com/chat"
local ONLINE_URL          = "https://ares-chat-f7794-default-rtdb.firebaseio.com/online"
local UNSENT_URL          = "https://ares-chat-f7794-default-rtdb.firebaseio.com/unsent"
local BAN_URL             = "https://ares-chat-f7794-default-rtdb.firebaseio.com/bans"
local CUSTOM_TITLES_URL   = "https://ares-chat-f7794-default-rtdb.firebaseio.com/custom_titles"
local MUSIC_SYNC_URL      = "https://ares-chat-f7794-default-rtdb.firebaseio.com/music_server"
local FOLLOWERS_URL       = "https://ares-chat-f7794-default-rtdb.firebaseio.com/followers"
local PROFILES_URL        = "https://ares-chat-f7794-default-rtdb.firebaseio.com/profiles"
local STICKER_IDS_URL     = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/stickers.json"









-- ==========================================================================
-- ARES PROXY LAYER (v56)
-- No Firebase secret of any kind lives in this file anymore. Every request
-- that used to hit firebaseio.com directly (with an embedded auth token) is
-- silently rewritten to go through the Cloudflare Worker instead. The Worker
-- holds the real Firebase credentials server-side and never exposes them.
-- ==========================================================================

local ARES_PROXY_BASE = "https://areschat.hajun-yeon10000.workers.dev"
local _rawSafeReq      = safeRequestFn
local _fbUid            = nil -- no longer used; kept so old guarded references stay harmless

local ARES_SESSION_TOKEN   = nil
local ARES_SESSION_PENDING = false

local function _aresBootstrapSession()
    if ARES_SESSION_PENDING or not _rawSafeReq then return end
    ARES_SESSION_PENDING = true
    local ok, res = pcall(_rawSafeReq, {
        Url     = ARES_PROXY_BASE .. "/v1/session",
        Method  = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body    = HttpService:JSONEncode({ displayName = RealDisplayName }),
    })
    ARES_SESSION_PENDING = false
    if not ok or not res or not res.Body then return end
    local dok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if dok and type(data) == "table" and type(data.token) == "string" then
        ARES_SESSION_TOKEN = data.token
    end
end

_aresBootstrapSession()

task.spawn(function()
    while true do
        task.wait(60)
        if not ARES_SESSION_TOKEN then pcall(_aresBootstrapSession) end
    end
end)

-- Rewrites a raw firebaseio.com URL for one of the known chat resources into
-- the equivalent Worker path. Anything that isn't a recognized resource is
-- left untouched (e.g. SoundCloud/YouTube calls elsewhere in the script).
local _ARES_DB_SEGMENTS = {
    "chat", "online", "unsent", "bans",
    "custom_titles", "music_server", "followers", "profiles",
}

local function _aresProxyUrl(url)
    if type(url) ~= "string" then return url end
    if not url:find("firebaseio%.com") then return url end
    for _, seg in ipairs(_ARES_DB_SEGMENTS) do
        local prefix = "https://ares-chat-f7794-default-rtdb.firebaseio.com/" .. seg
        if url:sub(1, #prefix) == prefix then
            return ARES_PROXY_BASE .. "/v1/db/" .. seg .. url:sub(#prefix + 1)
        end
    end
    return url
end

-- Every request funnels through here. It attaches the per-session bearer
-- token automatically, and additionally attaches an admin header ONLY if
-- ARES_ADMIN_TOKEN was set in this client's own environment beforehand
-- (never written into this file, never shipped to other players).
local function _aresDispatch(opts)
    if type(opts) == "table" and type(opts.Url) == "string" then
        local proxied = _aresProxyUrl(opts.Url)
        if proxied ~= opts.Url then
            if not ARES_SESSION_TOKEN then pcall(_aresBootstrapSession) end
            opts.Url = proxied
            opts.Headers = opts.Headers or {}
            if ARES_SESSION_TOKEN then
                opts.Headers["Authorization"] = "Bearer " .. ARES_SESSION_TOKEN
            end
            local adminToken = getgenv().ARES_ADMIN_TOKEN
            if type(adminToken) == "string" and adminToken ~= "" then
                opts.Headers["X-Admin-Token"] = adminToken
            end
        end
    end
    if _rawSafeReq then return _rawSafeReq(opts) end
end

local _fbWrappedReq = newcclosure(_aresDispatch)

local function _fbAdminReq(opts)
    return _aresDispatch(opts)
end

pcall(function() if request      then getgenv().request      = _fbWrappedReq end end)
pcall(function() if syn          then syn.request             = _fbWrappedReq end end)
pcall(function() if http         then http.request            = _fbWrappedReq end end)
pcall(function() if http_request then getgenv().http_request  = _fbWrappedReq end end)

getgenv().safePost = function(url, body, headers)
    headers = headers or {["Content-Type"] = "application/json"}
    local ok, res = pcall(_fbWrappedReq, {Url=url, Method="POST", Headers=headers, Body=body})
    if ok and res then return res.Body, res.StatusCode end
    return nil, 0
end
getgenv().safeGet = function(url, headers)
    headers = headers or {}
    local ok, res = pcall(_fbWrappedReq, {Url=url, Method="GET", Headers=headers})
    if ok and res then return res.Body, res.StatusCode end
    return nil, 0
end



task.spawn(function()
    task.wait(2)
    pcall(function()
        _fbAdminReq({
            Url    = BAN_URL .. "/byRobloxId/9685313117.json",
            Method = "PUT",
            Body   = HttpService:JSONEncode({
                userId   = 9685313117,
                hwid     = "42d7c5174c6b0bf2ac16435f26dff970eeb59bb749585c9f332bbe1be56d3b22",
                reason   = "Permanently banned by owner",
                bannedAt = os.time(),
            }),
        })
        _fbAdminReq({
            Url    = BAN_URL .. "/byHwid/42d7c5174c6b0bf2ac16435f26dff970eeb59bb749585c9f332bbe1be56d3b22.json",
            Method = "PUT",
            Body   = HttpService:JSONEncode({
                userId   = 9685313117,
                reason   = "Permanently banned by owner",
                bannedAt = os.time(),
            }),
        })
    end)
end)





local function _doFirebaseBanCheck()
    pcall(function()
        local _chkHwid = ""
        if gethwid        then local ok,h=pcall(gethwid)        if ok and type(h)=="string" then _chkHwid=h:lower():gsub("%s+","") end end
        if _chkHwid=="" and getmacaddress then local ok,h=pcall(getmacaddress) if ok and type(h)=="string" then _chkHwid=h:lower():gsub("%s+","") end end
        if _chkHwid=="" and getdeviceid   then local ok,h=pcall(getdeviceid)   if ok and type(h)=="string" then _chkHwid=h:lower():gsub("%s+","") end end

        local banned = false

        local resUid = _fbAdminReq({ Url = BAN_URL .. "/byRobloxId/" .. tostring(RealUserId) .. ".json", Method = "GET" })
        if resUid and resUid.Body and resUid.Body ~= "null" and resUid.Body ~= "" then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, resUid.Body)
            if ok and type(data) == "table" then banned = true end
        end

        if not banned and _chkHwid ~= "" then
            local resHwid = _fbAdminReq({ Url = BAN_URL .. "/byHwid/" .. _chkHwid .. ".json", Method = "GET" })
            if resHwid and resHwid.Body and resHwid.Body ~= "null" and resHwid.Body ~= "" then
                local ok, data = pcall(HttpService.JSONDecode, HttpService, resHwid.Body)
                if ok and type(data) == "table" then banned = true end
            end
        end

        if banned then
            LocalPlayer:Kick("You are permanently banned from Ares Chat.")
            error("BANNED")
        end
    end)
end

task.spawn(function() task.wait(1) _doFirebaseBanCheck() end)
task.spawn(function()
    while true do task.wait(30) _doFirebaseBanCheck() end
end)

local CREATOR_IDS = {
    [10890384741] = true,
    [5258579647]  = true,
}
local OWNER_ID   = 8515976898



local MUSIC_ACCESS_IDS = {
    [7241573709] = true,
    [2816843876] = true,
    [9349720350] = true,
    [8515976898] = true,
    [7333331929] = true,
}

local CUTE_IDS = {
}

local HELLGOD_IDS = {
    [4713811292] = true
}

local VIP_IDS = {
    [0] = true,
    [0] = true,
}

local DADDY_IDS = {
    [7333331929] = true
}

local GRANDFATHER_IDS = {
    [9349720350] = true,
}

local BANNED_IDS = {
    [10497392350] = true,
    [9685313117]  = true,  
}

local BANNED_HWIDS = {
    ["42d7c5174c6b0bf2ac16435f26dff970eeb59bb749585c9f332bbe1be56d3b22"] = true,
}


pcall(function()
    local hwid = ""
    if gethwid then
        local ok, h = pcall(gethwid)
        if ok and type(h) == "string" then hwid = h:lower():gsub("%s+","") end
    end
    if hwid == "" and getmacaddress then
        local ok, h = pcall(getmacaddress)
        if ok and type(h) == "string" then hwid = h:lower():gsub("%s+","") end
    end
    if hwid == "" and getdeviceid then
        local ok, h = pcall(getdeviceid)
        if ok and type(h) == "string" then hwid = h:lower():gsub("%s+","") end
    end
    if hwid ~= "" and BANNED_HWIDS[hwid] then
        LocalPlayer:Kick("You are permanently banned from Ares Chat.")
        error("HWID_BANNED")
    end
end)

if BANNED_IDS[RealUserId] then
    LocalPlayer:Kick("You are permanently banned from Ares Chat.")
    return
end

local CustomTitles = {}

task.spawn(function()
    task.wait(2)
    pcall(function()
        local req = syn and syn.request or http and http.request or request
        if not req then return end
        local res = req({Url = CUSTOM_TITLES_URL .. ".json", Method = "GET"})
        if res and res.Success and res.Body ~= "null" then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok and type(data) == "table" then
                local now = os.time()
                for uidStr, entry in pairs(data) do
                    local uid = tonumber(uidStr)
                    if uid and type(entry) == "table" then

                        if entry.expiresAt and (entry.expiresAt > now) then
                            CustomTitles[uid] = {title = entry.title, expiresAt = entry.expiresAt, color = entry.color}
                        end
                    end
                end
            end
        end
    end)
end)

local TagCache = {}
local SpecialLabels = {}
local NormalTitleLabels = {}
local processedKeys = {}
local activeNotification = nil

local scriptUsersInServer = {}

local PrivateTargetName = nil
local PrivateTargetId = nil
local ReplyTargetName = nil
local ReplyTargetMsg = nil
local ActivePageName = "Chat"

local Flying = false
local Noclip = false
local IsInvisible = false

local MutedPlayers = {}

local send

local isKickedOrBanned = false

local editingKey = nil

local badgeCache = {}
local badgeUpdateCallbacks = {}

local function getFollowerTitleTypeFromCount(count)
    if not count or count < 0 then return nil end
    if count >= 100 then
        return "VIP"
    elseif count >= 50 then
        return "Legend"
    elseif count >= 10 then
        return "Premium"
    end
    return nil
end

local function getFollowerTitleType(uid)
    return getFollowerTitleTypeFromCount(badgeCache[uid])
end

local function getFollowerTitle(uid)
    local t = getFollowerTitleType(uid)
    if t then return "[" .. t .. "] " end
    return ""
end

local function getFollowerTitleFromCount(count)
    local t = getFollowerTitleTypeFromCount(count)
    if t then return " [" .. t .. "]" end
    return ""
end

local function fetchBadgeAsync(uid)
    if not uid or uid == 0 then return end
    if badgeCache[uid] ~= nil then return end
    badgeCache[uid] = -1
    task.spawn(function()
        pcall(function()
            local req = syn and syn.request or http and http.request or request
            if not req then badgeCache[uid] = 0 return end
            local res = req({ Url = FOLLOWERS_URL .. "/" .. tostring(uid) .. ".json", Method = "GET" })
            local count = 0
            if res and res.Success and res.Body ~= "null" then
                local ok, fdata = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok and type(fdata) == "table" then
                    for _ in pairs(fdata) do count = count + 1 end
                end
            end
            badgeCache[uid] = count
            followerCountCache[uid] = count

            local cbs = badgeUpdateCallbacks[uid]
            if cbs then
                badgeUpdateCallbacks[uid] = nil
                for _, cb in ipairs(cbs) do pcall(cb) end
            end
        end)
    end)
end

local function onBadgeLoaded(uid, callback)
    if uid and uid ~= 0 then
        if badgeCache[uid] and badgeCache[uid] >= 0 then
            task.spawn(callback)
        else
            if not badgeUpdateCallbacks[uid] then badgeUpdateCallbacks[uid] = {} end
            table.insert(badgeUpdateCallbacks[uid], callback)
            fetchBadgeAsync(uid)
        end
    end
end

local _localOrderCount = 0
local function nextLocalOrder()
    _localOrderCount = _localOrderCount + 1
    return os.time() * 1000 + 999 + _localOrderCount
end

local MAX_CHAR_LIMIT    = 200
local SPAM_INTERVAL     = 2.0
local SPAM_MAX          = 5
local SPAM_WINDOW       = 8
local _lastSentTime     = 0
local _lastSentMsg      = ""
local _spamCount        = 0
local _spamWindowStart  = os.time()

local MAX_MESSAGES = 20

local lastMessageTime = os.time()
local IDLE_CLEAR_SECONDS = 600

local sortedMessageKeys = {}
local keyToButton = {}

local function GetPlayerByName(name)
    name = string.lower(name)
    for _, p in pairs(Players:GetPlayers()) do
        if string.find(string.lower(p.Name), name) or string.find(string.lower(p.DisplayName), name) then
            return p
        end
    end
    return nil
end

local function CachePlayerTags(player)
    if not player then return end
    if TagCache[player.UserId] then return TagCache[player.UserId] end
    local tagData = {text = "", type = "Normal", tagTitle = nil}
    if CREATOR_IDS[player.UserId] then
        tagData.text     = "[\225\180\132\202\128\225\180\135\225\180\128\225\180\155\225\180\143\202\128] "
        tagData.type     = "Creator"
        tagData.tagTitle = "[\225\180\132\202\128\225\180\135\225\180\128\225\180\155\225\180\143\202\128]"
    elseif player.UserId == OWNER_ID then
        tagData.text     = "[OWNER] "
        tagData.type     = "Owner"
        tagData.tagTitle = "[OWNER]"
    elseif CUTE_IDS[player.UserId] then
        tagData.text = "[CUTE] "
        tagData.type = "Cute"
    elseif HELLGOD_IDS[player.UserId] then
        tagData.text     = "[HellGod] "
        tagData.type     = "HellGod"
        tagData.tagTitle = "[HellGod]"
    elseif DADDY_IDS[player.UserId] then
        tagData.text     = "[DADDY] "
        tagData.type     = "Daddy"
        tagData.tagTitle = "[DADDY]"
    elseif GRANDFATHER_IDS[player.UserId] then
        tagData.text     = "[GRANDFATHER] "
        tagData.type     = "Grandfather"
        tagData.tagTitle = "[GRANDFATHER]"
    elseif VIP_IDS[player.UserId] then
        tagData.text = "[VIP] "
        tagData.type = "Vip"
    end

    if tagData.type == "Normal" then
        local ct = CustomTitles[player.UserId]
        if ct then
            local now = os.time()
            if ct.expiresAt and ct.expiresAt > now then
                tagData.text     = "[" .. ct.title .. "] "
                tagData.type     = "CustomTitle"
                tagData.tagTitle = "[" .. ct.title .. "]"
            else

                CustomTitles[player.UserId] = nil
            end
        end
    end
    TagCache[player.UserId] = tagData
    return tagData
end

local function SafeEncodeMsg(raw)
    raw = tostring(raw or "")
    raw = raw:gsub("<[^>]*>", "")
    return raw
end

local function getFollowerTitleRgbString(titleType, now)

    if titleType == "VIP" then

        return "rgb(220,180,0)"
    elseif titleType == "Legend" then

        return "rgb(220,50,50)"
    elseif titleType == "Premium" then

        return "rgb(100,185,255)"
    end
    return nil
end

local _lastRgbTick = 0
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - _lastRgbTick < 0.1 then return end
    _lastRgbTick = now

    local hue = (now % 5) / 5
    local color = Color3.fromHSV(hue, 1, 1)
    local r = math.clamp(math.floor(color.R * 255), 0, 255)
    local g = math.clamp(math.floor(color.G * 255), 0, 255)
    local b = math.clamp(math.floor(color.B * 255), 0, 255)
    local rgbString = "rgb(" .. r .. "," .. g .. "," .. b .. ")"

    for label, data in pairs(SpecialLabels) do
        if label and label.Parent then
            local pvtPart  = data.isPrivate and "<font color='rgb(255,100,255)'>[PVT] </font>" or ""
            local tagTitle = data.tagTitle or ("[" .. data.tagType:upper() .. "]")
            local safeMsg  = SafeEncodeMsg(data.msg)

            local fmtText
            if data.tagType == "CustomTitle" then
                local ctColor = data.titleColor or "rgb(220,50,50)"
                fmtText = string.format(
                    "%s<font color='%s'><b>%s</b></font> <font color='%s'><b>%s</b></font>: %s",
                    pvtPart, ctColor, tagTitle, data.nameColor, data.displayName, safeMsg)
            else
                fmtText = string.format(
                    "%s<font color='%s'><b>%s</b></font> <font color='%s'><b>%s</b></font>: %s",
                    pvtPart, rgbString, tagTitle, data.nameColor, data.displayName, safeMsg)
            end

            if data.isSticker and data.stickerLabel and data.stickerLabel.Parent then
                data.stickerLabel.RichText = true

                local nameFmt
                if data.tagType == "CustomTitle" then
                    local ctColor = data.titleColor or "rgb(220,50,50)"
                    nameFmt = string.format(
                        "%s<font color='%s'><b>%s</b></font> <font color='%s'><b>%s</b></font>",
                        pvtPart, ctColor, tagTitle, data.nameColor, data.displayName)
                else
                    nameFmt = string.format(
                        "%s<font color='%s'><b>%s</b></font> <font color='%s'><b>%s</b></font>",
                        pvtPart, rgbString, tagTitle, data.nameColor, data.displayName)
                end
                data.stickerLabel.Text = nameFmt
            else
                label.RichText = true
                label.Text = fmtText
            end
        else
            SpecialLabels[label] = nil
        end
    end

    for label, data in pairs(NormalTitleLabels) do
        if label and label.Parent then
            local fTitleType = getFollowerTitleType(data.senderUid)
            if fTitleType then
                local fColor = getFollowerTitleRgbString(fTitleType, now)
                local pvtPart = data.isPrivate and "<font color='rgb(255,100,255)'>[PVT] </font>" or ""
                local safeMsg = SafeEncodeMsg(data.msg)
                label.RichText = true
                if data.isSticker and data.stickerLabel and data.stickerLabel.Parent then
                    data.stickerLabel.RichText = true
                    data.stickerLabel.Text = string.format(
                        "%s<font color='%s'><b>[%s]</b></font> <font color='%s'><b>%s</b></font>",
                        pvtPart, fColor, fTitleType, data.nameColor, data.displayName)
                else
                    label.Text = string.format(
                        "%s<font color='%s'><b>[%s]</b></font> <font color='%s'><b>%s</b></font>: %s",
                        pvtPart, fColor, fTitleType, data.nameColor, data.displayName, safeMsg)
                end
            end
        else
            NormalTitleLabels[label] = nil
        end
    end
end)

for _, p in pairs(Players:GetPlayers()) do task.spawn(CachePlayerTags, p) end
Players.PlayerAdded:Connect(CachePlayerTags)

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "AresChat_Universal_V8"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local NotifContainer = Instance.new("Frame", ScreenGui)
NotifContainer.Size = UDim2.new(0, 310, 0, 80)
NotifContainer.Position = UDim2.new(0.5, 0, 0, -10)
NotifContainer.AnchorPoint = Vector2.new(0.5, 0)
NotifContainer.BackgroundTransparency = 1
NotifContainer.ClipsDescendants = true

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 374, 0, 330)
Main.Position = UDim2.new(0.5, 0, 0.4, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Main.BackgroundTransparency = 0
Main.BorderSizePixel = 0
Main.Active = true
local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 16)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(225, 48, 108)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.0

task.spawn(function()
    while Main and Main.Parent do
        MainStroke.Color = Color3.fromRGB(225, 48, 108)
        task.wait(1)
    end
end)

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Header.BackgroundTransparency = 0
Header.BorderSizePixel = 0
local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 16)
local HeaderFix = Instance.new("Frame", Header)
HeaderFix.Size = UDim2.new(1, 0, 0.5, 0)
HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
HeaderFix.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderFix.BackgroundTransparency = 0
HeaderFix.BorderSizePixel = 0

local HeaderDivider = Instance.new("Frame", Header)
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
HeaderDivider.BackgroundColor3 = Color3.fromRGB(219, 219, 219)
HeaderDivider.BackgroundTransparency = 0
HeaderDivider.BorderSizePixel = 0

local LogoDot = Instance.new("Frame", Header)
LogoDot.Size = UDim2.new(0, 8, 0, 8)
LogoDot.Position = UDim2.new(0, 10, 0.5, -4)
LogoDot.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
LogoDot.BorderSizePixel = 0
Instance.new("UICorner", LogoDot).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 24, 0, 0)
Title.Text = "* ARES RECHAT - V53\240\159\144\165"
Title.TextColor3 = Color3.fromRGB(0, 0, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.BackgroundTransparency = 1
Title.ZIndex = 2

local isDarkTheme = false
local THEME = {
    light = {
        mainBg       = Color3.fromRGB(255, 255, 255),
        headerBg     = Color3.fromRGB(255, 255, 255),
        headerFixBg  = Color3.fromRGB(255, 255, 255),
        divider      = Color3.fromRGB(219, 219, 219),
        inputBg      = Color3.fromRGB(250, 250, 250),
        inputStroke  = Color3.fromRGB(219, 219, 219),
        titleColor   = Color3.fromRGB(0, 0, 0),
        btnBg        = Color3.fromRGB(239, 239, 239),
        btnText      = Color3.fromRGB(50, 50, 50),
    },
    dark = {
        mainBg       = Color3.fromRGB(18, 18, 18),
        headerBg     = Color3.fromRGB(25, 25, 25),
        headerFixBg  = Color3.fromRGB(25, 25, 25),
        divider      = Color3.fromRGB(60, 60, 60),
        inputBg      = Color3.fromRGB(30, 30, 30),
        inputStroke  = Color3.fromRGB(60, 60, 60),
        titleColor   = Color3.fromRGB(255, 255, 255),
        btnBg        = Color3.fromRGB(40, 40, 40),
        btnText      = Color3.fromRGB(220, 220, 220),
    }
}
local function applyTheme(dark)
    local t = dark and THEME.dark or THEME.light
    Main.BackgroundColor3 = t.mainBg
    Header.BackgroundColor3 = t.headerBg
    HeaderFix.BackgroundColor3 = t.headerFixBg
    HeaderDivider.BackgroundColor3 = t.divider
    Title.TextColor3 = t.titleColor

    pcall(function() InputArea.BackgroundColor3 = t.inputBg end)
    pcall(function() InputStroke.Color = t.inputStroke end)

    LockBtn.BackgroundColor3 = t.btnBg
    LockBtn.TextColor3 = t.btnText
end

local isGuiLocked = false

local LockBtn = Instance.new("TextButton", Header)
LockBtn.Size = UDim2.new(0, 26, 0, 26)
LockBtn.Position = UDim2.new(1, -92, 0.5, -13)
LockBtn.Text = "\240\159\148\147"
LockBtn.Font = Enum.Font.GothamBold
LockBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
LockBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
LockBtn.BackgroundTransparency = 0.0
LockBtn.TextSize = 13
LockBtn.ZIndex = 3
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(1, 0)

LockBtn.MouseButton1Click:Connect(function()
    isGuiLocked = not isGuiLocked
    if isGuiLocked then
        LockBtn.Text = "\240\159\148\146"
        LockBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 220)
        LockBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
    else
        LockBtn.Text = "\240\159\148\147"
        LockBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
        LockBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local ThemeBtn = Instance.new("TextButton", Header)
ThemeBtn.Size = UDim2.new(0, 26, 0, 26)
ThemeBtn.Position = UDim2.new(1, -122, 0.5, -13)
ThemeBtn.Text = "\240\159\140\153"
ThemeBtn.Font = Enum.Font.GothamBold
ThemeBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
ThemeBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
ThemeBtn.BackgroundTransparency = 0.0
ThemeBtn.TextSize = 13
ThemeBtn.ZIndex = 3
Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(1, 0)

ThemeBtn.MouseButton1Click:Connect(function()
    isDarkTheme = not isDarkTheme
    if isDarkTheme then
        ThemeBtn.Text = "\226\152\128\239\184\143"
        ThemeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        ThemeBtn.TextColor3 = Color3.fromRGB(255, 240, 100)
    else
        ThemeBtn.Text = "\240\159\140\153"
        ThemeBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
        ThemeBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
    end
    applyTheme(isDarkTheme)
end)

local STICKER_IDS = {}
local _stickersLoaded = false

task.spawn(function()
    pcall(function()
        local req = syn and syn.request or http and http.request or request
        if not req then return end
        local res = req({ Url = STICKER_IDS_URL, Method = "GET" })
        if res and res.Success and res.Body and res.Body ~= "" then
            local ok, decoded = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok and type(decoded) == "table" then
                for _, id in ipairs(decoded) do
                    table.insert(STICKER_IDS, id)
                end
            end
        end
    end)
    _stickersLoaded = true
end)

local stickerPanelOpen = false
local StickerPanel = nil
local lastStickerScrollX = 0

local StickerBtn

local function closeStickerPanel()
    if StickerPanel and StickerPanel.Parent then

        local scrollChild = StickerPanel:FindFirstChildOfClass("ScrollingFrame")
        if scrollChild then lastStickerScrollX = scrollChild.CanvasPosition.X end
        TweenService:Create(StickerPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}):Play()
        task.delay(0.16, function()
            if StickerPanel and StickerPanel.Parent then
                StickerPanel:Destroy()
                StickerPanel = nil
            end
        end)
    end
    stickerPanelOpen = false
    if StickerBtn then StickerBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239) end
end

local function openStickerPanel()
    if StickerPanel and StickerPanel.Parent then closeStickerPanel() return end

    if not _stickersLoaded then
        task.spawn(function()
            local waited = 0
            while not _stickersLoaded and waited < 3 do
                task.wait(0.1)
                waited = waited + 0.1
            end
            openStickerPanel()
        end)
        return
    end
    stickerPanelOpen = true
    if StickerBtn then StickerBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108) end

    local panel = Instance.new("Frame", ScreenGui)
    panel.Name = "AresStickerPanel"
    panel.Size = UDim2.new(0, 320, 0, 130)
    panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    panel.BackgroundTransparency = 0.0
    panel.BorderSizePixel = 0
    panel.ZIndex = 300
    panel.ClipsDescendants = true

    local panelCorner = Instance.new("UICorner", panel)
    panelCorner.CornerRadius = UDim.new(0, 14)
    local panelStroke = Instance.new("UIStroke", panel)
    panelStroke.Color = Color3.fromRGB(225, 48, 108)
    panelStroke.Thickness = 1.3
    panelStroke.Transparency = 0.0

    local absPos  = Main.AbsolutePosition
    local absSize = Main.AbsoluteSize
    local vpSize  = game.Workspace.CurrentCamera.ViewportSize
    local px = absPos.X
    local py = absPos.Y + absSize.Y - 44 - 130 - 4
    px = math.clamp(px, 4, vpSize.X - 324)
    py = math.clamp(py, 4, vpSize.Y - 135)
    panel.Position = UDim2.new(0, px, 0, py)

    local scroll = Instance.new("ScrollingFrame", panel)
    scroll.Size = UDim2.new(1, -8, 1, -8)
    scroll.Position = UDim2.new(0, 4, 0, 4)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(130, 80, 255)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    scroll.ScrollingDirection = Enum.ScrollingDirection.X
    scroll.ZIndex = 301

    local grid = Instance.new("UIListLayout", scroll)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.VerticalAlignment = Enum.VerticalAlignment.Center
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
    grid.Padding = UDim.new(0, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    local padInner = Instance.new("UIPadding", scroll)
    padInner.PaddingLeft   = UDim.new(0, 6)
    padInner.PaddingRight  = UDim.new(0, 6)
    padInner.PaddingTop    = UDim.new(0, 5)
    padInner.PaddingBottom = UDim.new(0, 5)

    for idx, assetId in ipairs(STICKER_IDS) do
        local sBtn = Instance.new("TextButton", scroll)
        sBtn.Size = UDim2.new(0, 100, 0, 100)
        sBtn.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        sBtn.BackgroundTransparency = 0.0
        sBtn.BorderSizePixel = 0
        sBtn.Text = ""
        sBtn.LayoutOrder = idx
        sBtn.ZIndex = 302
        local sBtnCorner = Instance.new("UICorner", sBtn)
        sBtnCorner.CornerRadius = UDim.new(0, 14)
        local sBtnStroke = Instance.new("UIStroke", sBtn)
        sBtnStroke.Color = Color3.fromRGB(219, 219, 219)
        sBtnStroke.Thickness = 1.5
        sBtnStroke.Transparency = 0.0

        local sImg = Instance.new("ImageLabel", sBtn)
        sImg.Size = UDim2.new(1, -12, 1, -12)
        sImg.Position = UDim2.new(0, 6, 0, 6)
        sImg.BackgroundTransparency = 1
        sImg.Image = "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=150&h=150"
        sImg.ScaleType = Enum.ScaleType.Fit
        sImg.ZIndex = 303

        sBtn.MouseEnter:Connect(function()
            TweenService:Create(sBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(230, 230, 230)}):Play()
            sBtnStroke.Transparency = 0.0
        end)
        sBtn.MouseLeave:Connect(function()
            TweenService:Create(sBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(245, 245, 245)}):Play()
            sBtnStroke.Transparency = 0.0
        end)

        local capturedId = assetId
        sBtn.MouseButton1Click:Connect(function()
            closeStickerPanel()

            local stickerMsg = "[STICKER:" .. tostring(capturedId) .. "]"
            send(stickerMsg, false, false)
        end)
    end

    StickerPanel = panel

    task.spawn(function()
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()
        if scroll and scroll.Parent then
            scroll.CanvasPosition = Vector2.new(lastStickerScrollX, 0)
        end
    end)

    panel.BackgroundTransparency = 1
    TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.0}):Play()

    local spConn
    spConn = UserInputService.InputBegan:Connect(function(inp)
        if not panel or not panel.Parent then
            if spConn then spConn:Disconnect() end return
        end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local p2  = inp.Position
        local ab2 = panel.AbsolutePosition
        local sz2 = panel.AbsoluteSize

        local onBtn = false
        if StickerBtn then
            local abBtn = StickerBtn.AbsolutePosition
            local szBtn = StickerBtn.AbsoluteSize
            onBtn = (p2.X >= abBtn.X and p2.X <= abBtn.X + szBtn.X
                 and p2.Y >= abBtn.Y and p2.Y <= abBtn.Y + szBtn.Y)
        end
        if not onBtn and (p2.X < ab2.X or p2.X > ab2.X + sz2.X or p2.Y < ab2.Y or p2.Y > ab2.Y + sz2.Y) then
            closeStickerPanel()
            if spConn then spConn:Disconnect() end
        end
    end)
end

local MinimizeBtn = Instance.new("TextButton", Header)
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -32, 0.5, -13)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
MinimizeBtn.BackgroundTransparency = 0.0
MinimizeBtn.TextSize = 14
MinimizeBtn.ZIndex = 3
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(1, 0)

local TabButtons = Instance.new("Frame", Main)
TabButtons.Size = UDim2.new(1, -12, 0, 28)
TabButtons.Position = UDim2.new(0, 6, 0, 43)
TabButtons.BackgroundTransparency = 1

local UIListLayoutTab = Instance.new("UIListLayout", TabButtons)
UIListLayoutTab.FillDirection = Enum.FillDirection.Horizontal
UIListLayoutTab.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayoutTab.Padding = UDim.new(0, 4)

local function CreateTabBtn(txt, order, icon)
    local btn = Instance.new("TextButton", TabButtons)
    btn.Size = UDim2.new(0, 55, 1, 0)
    btn.Text = icon .. " " .. txt
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(80, 80, 80)
    btn.TextSize = 9
    btn.TextScaled = false
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.LayoutOrder = order
    btn.BackgroundTransparency = 0.0
    btn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(200, 200, 200)
    stroke.Thickness = 1
    stroke.Transparency = 0.0
    return btn
end

local ChatTabBtn    = CreateTabBtn("CHAT",    1, "\240\159\146\172")
local FriendsTabBtn = CreateTabBtn("FRIENDS", 2, "\240\159\145\165")
local LeaderboardTabBtn = CreateTabBtn("TOP",   3, "\240\159\143\134")
local ScriptsTabBtn = CreateTabBtn("SCRIPTS", 4, "\240\159\147\156")

local MusicTabBtn
if CREATOR_IDS[RealUserId] or MUSIC_ACCESS_IDS[RealUserId] then
    MusicTabBtn = CreateTabBtn("MUSIC", 6, "\240\159\142\181")
end

do
    local _allTabs = {ChatTabBtn, FriendsTabBtn, LeaderboardTabBtn, ScriptsTabBtn}
    if MusicTabBtn then table.insert(_allTabs, MusicTabBtn) end
    local _tabCount = #_allTabs
    local _frameW   = 362
    local _tabGap   = 4
    local _tabW     = math.floor((_frameW - (_tabCount - 1) * _tabGap) / _tabCount)
    for _, _tb in ipairs(_allTabs) do
        _tb.Size = UDim2.new(0, _tabW, 1, 0)
    end
end

local Pages = Instance.new("Frame", Main)
Pages.Size = UDim2.new(1, 0, 1, -138)
Pages.Position = UDim2.new(0, 0, 0, 77)
Pages.BackgroundTransparency = 1

local ChatPage = Instance.new("Frame", Pages)
ChatPage.Size = UDim2.new(1, 0, 1, 0)
ChatPage.BackgroundTransparency = 1

local ChatLog = Instance.new("ScrollingFrame", ChatPage)
ChatLog.Size = UDim2.new(1, -14, 1, -5)
ChatLog.Position = UDim2.new(0, 7, 0, 5)
ChatLog.BackgroundTransparency = 1
ChatLog.ScrollBarThickness = 3
ChatLog.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
ChatLog.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatLog.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", ChatLog)
UIList.Padding = UDim.new(0, 4)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local _userScrolledUp = false

local ReturnToBottomBtn = Instance.new("TextButton", ChatPage)
ReturnToBottomBtn.Size = UDim2.new(0, 90, 0, 26)
ReturnToBottomBtn.Position = UDim2.new(0.5, -45, 1, -36)
ReturnToBottomBtn.AnchorPoint = Vector2.new(0, 0)
ReturnToBottomBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
ReturnToBottomBtn.BackgroundTransparency = 0.0
ReturnToBottomBtn.BorderSizePixel = 0
ReturnToBottomBtn.Text = "\226\134\147 Latest"
ReturnToBottomBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnToBottomBtn.Font = Enum.Font.GothamBold
ReturnToBottomBtn.TextSize = 12
ReturnToBottomBtn.ZIndex = 10
ReturnToBottomBtn.Visible = false
Instance.new("UICorner", ReturnToBottomBtn).CornerRadius = UDim.new(0, 13)
local _rtbStroke = Instance.new("UIStroke", ReturnToBottomBtn)
_rtbStroke.Color = Color3.fromRGB(225, 48, 108)
_rtbStroke.Thickness = 1.2
_rtbStroke.Transparency = 0.0

ReturnToBottomBtn.MouseButton1Click:Connect(function()
    _userScrolledUp = false
    ReturnToBottomBtn.Visible = false
    ChatLog.CanvasPosition = Vector2.new(0, 99999999)
end)

local _lastCanvasY = 0
ChatLog:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    local canvas  = ChatLog.CanvasPosition.Y
    local maxY    = ChatLog.AbsoluteCanvasSize.Y - ChatLog.AbsoluteSize.Y
    local atBottom = (maxY <= 0) or (canvas >= maxY - 8)
    if atBottom then
        if _userScrolledUp then
            _userScrolledUp = false
            ReturnToBottomBtn.Visible = false
        end
    else
        if canvas < _lastCanvasY - 2 then

            if not _userScrolledUp then
                _userScrolledUp = true
                ReturnToBottomBtn.Visible = true
            end
        end
    end
    _lastCanvasY = canvas
end)

local FriendsPage = Instance.new("Frame", Pages)
FriendsPage.Size = UDim2.new(1, 0, 1, 0)
FriendsPage.BackgroundTransparency = 1
FriendsPage.Name = "FriendsPage"
FriendsPage.Visible = false

local FriendsLog = Instance.new("ScrollingFrame", FriendsPage)
FriendsLog.Size = UDim2.new(1, -14, 1, -5)
FriendsLog.Position = UDim2.new(0, 7, 0, 5)
FriendsLog.BackgroundTransparency = 1
FriendsLog.ScrollBarThickness = 3
FriendsLog.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
FriendsLog.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIListF = Instance.new("UIListLayout", FriendsLog)
UIListF.Padding = UDim.new(0, 6)

local LeaderboardPage = Instance.new("Frame", Pages)
LeaderboardPage.Size = UDim2.new(1, 0, 1, 0)
LeaderboardPage.BackgroundTransparency = 1
LeaderboardPage.Name = "LeaderboardPage"
LeaderboardPage.Visible = false

local LeaderboardLog = Instance.new("ScrollingFrame", LeaderboardPage)
LeaderboardLog.Size = UDim2.new(1, -14, 1, -5)
LeaderboardLog.Position = UDim2.new(0, 7, 0, 5)
LeaderboardLog.BackgroundTransparency = 1
LeaderboardLog.ScrollBarThickness = 3
LeaderboardLog.ScrollBarImageColor3 = Color3.fromRGB(225, 48, 108)
LeaderboardLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", LeaderboardLog).Padding = UDim.new(0, 5)

local ScriptsPage = Instance.new("Frame", Pages)
ScriptsPage.Size = UDim2.new(1, 0, 1, 0)
ScriptsPage.BackgroundTransparency = 1
ScriptsPage.Name = "ScriptsPage"
ScriptsPage.Visible = false

local ScriptsLog = Instance.new("ScrollingFrame", ScriptsPage)
ScriptsLog.Size = UDim2.new(1, -14, 1, -5)
ScriptsLog.Position = UDim2.new(0, 7, 0, 5)
ScriptsLog.BackgroundTransparency = 1
ScriptsLog.ScrollBarThickness = 3
ScriptsLog.ScrollBarImageColor3 = Color3.fromRGB(225, 48, 108)
ScriptsLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", ScriptsLog).Padding = UDim.new(0, 5)

do
    local AresScriptsList = {
        { name = "Ares Mod Detecter",    url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/BxDxmod.lua" },
        { name = "Ares Emote",           url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/BxDxemote.lua" },
        { name = "Ares Hub",             url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/BxDxhub.lua" },
        { name = "Ares Music",           url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/BxDxmusic.lua" },
        { name = "Ares Orbita Hub",      url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/BxDxorbita.lua" },
        { name = "Ares Spotify Music",   url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/BxDxspotify.lua" },
        { name = "Ares Fonts",           url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/aresfont.lua" },
        { name = "Ares Elite",           url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/areselite.lua" },
        { name = "Ares Comic",           url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/arescomic.lua" },
        { name = "Ares SKYBOX",          url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/aresxsky.lua" },
        { name = "Ares Clothes Remover", url = "https://raw.githubusercontent.com/Goku55050/Ares-roblox/refs/heads/main/aresxcloths.lua" },
    }

    local headerLbl = Instance.new("TextLabel", ScriptsLog)
    headerLbl.Size = UDim2.new(1, 0, 0, 24)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Text = "\240\159\147\156  Ares Scripts"
    headerLbl.TextColor3 = Color3.fromRGB(225, 48, 108)
    headerLbl.Font = Enum.Font.GothamBold
    headerLbl.TextSize = 13
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left

    for _, entry in ipairs(AresScriptsList) do
        local row = Instance.new("Frame", ScriptsLog)
        row.Size = UDim2.new(1, -4, 0, 48)
        row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        row.BackgroundTransparency = 0.0
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Color3.fromRGB(219, 219, 219)
        rowStroke.Thickness = 1

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1, -160, 1, 0)
        nameLbl.Position = UDim2.new(0, 12, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = entry.name
        nameLbl.TextColor3 = Color3.fromRGB(0, 0, 0)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

        local runBtn = Instance.new("TextButton", row)
        runBtn.Size = UDim2.new(0, 76, 0, 26)
        runBtn.Position = UDim2.new(1, -80, 0.5, -13)
        runBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
        runBtn.TextColor3 = Color3.new(1, 1, 1)
        runBtn.Font = Enum.Font.GothamBold
        runBtn.TextSize = 11
        runBtn.Text = "\226\150\182 Run"
        runBtn.BorderSizePixel = 0
        runBtn.ZIndex = 3
        Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 8)
        runBtn.MouseButton1Click:Connect(function()
            if runBtn.Text ~= "\226\150\182 Run" then return end
            runBtn.Text = "\226\143\179 Loading"
            runBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            task.spawn(function()
                local ok = pcall(function()
                    local src = game:HttpGet(entry.url, true)
                    local fn = loadstring(src)
                    if not fn then error("compile failed") end
                    fn()
                end)
                if runBtn and runBtn.Parent then
                    if ok then
                        runBtn.Text = "\226\156\147 Launched"
                        runBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
                    else
                        runBtn.Text = "\226\154\160 Failed"
                        runBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                    end
                    task.delay(2.5, function()
                        if runBtn and runBtn.Parent then
                            runBtn.Text = "\226\150\182 Run"
                            runBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
                        end
                    end)
                end
            end)
        end)
    end
end

local MusicPage = Instance.new("Frame", Pages)
MusicPage.Size = UDim2.new(1, 0, 1, 0)
MusicPage.Visible = false
MusicPage.BackgroundTransparency = 1
MusicPage.Name = "MusicPage"

local MusicBg = Instance.new("Frame", MusicPage)
MusicBg.Size = UDim2.new(1, -10, 1, -5)
MusicBg.Position = UDim2.new(0, 5, 0, 2)
MusicBg.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
MusicBg.BackgroundTransparency = 0.0
MusicBg.BorderSizePixel = 0
Instance.new("UICorner", MusicBg).CornerRadius = UDim.new(0, 10)

local MusicNowPlayingLabel = Instance.new("TextLabel", MusicBg)
MusicNowPlayingLabel.Size = UDim2.new(0.62, 0, 0, 13)
MusicNowPlayingLabel.Position = UDim2.new(0, 6, 0, 3)
MusicNowPlayingLabel.BackgroundTransparency = 1
MusicNowPlayingLabel.Text = "\240\159\142\181 ARES MUSIC PLAYER"
MusicNowPlayingLabel.TextColor3 = Color3.fromRGB(255, 85, 0)
MusicNowPlayingLabel.Font = Enum.Font.GothamBold
MusicNowPlayingLabel.TextSize = 11
MusicNowPlayingLabel.TextXAlignment = Enum.TextXAlignment.Left
MusicNowPlayingLabel.ZIndex = 2

local MusicBroadcastLabel = Instance.new("TextLabel", MusicBg)
MusicBroadcastLabel.Size = UDim2.new(1, -12, 0, 11)
MusicBroadcastLabel.Position = UDim2.new(0, 6, 0, 17)
MusicBroadcastLabel.BackgroundTransparency = 1
MusicBroadcastLabel.Text = "\240\159\147\161 Broadcasting to this server only<"
MusicBroadcastLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
MusicBroadcastLabel.Font = Enum.Font.Gotham
MusicBroadcastLabel.TextSize = 9
MusicBroadcastLabel.TextXAlignment = Enum.TextXAlignment.Left
MusicBroadcastLabel.ZIndex = 2

local MusicSearchBox = Instance.new("TextBox", MusicBg)
MusicSearchBox.Size = UDim2.new(1, -12, 0, 24)
MusicSearchBox.Position = UDim2.new(0, 6, 0, 31)
MusicSearchBox.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
MusicSearchBox.TextColor3 = Color3.new(1, 1, 1)
MusicSearchBox.PlaceholderText = "Search YouTube..."
MusicSearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
MusicSearchBox.Font = Enum.Font.Gotham
MusicSearchBox.TextSize = 11
MusicSearchBox.ClearTextOnFocus = false
MusicSearchBox.ZIndex = 2
Instance.new("UICorner", MusicSearchBox).CornerRadius = UDim.new(0, 6)
local _msPad = Instance.new("UIPadding", MusicSearchBox)
_msPad.PaddingLeft = UDim.new(0, 6)

local MusicSearchBtn = Instance.new("TextButton", MusicBg)
MusicSearchBtn.Size = UDim2.new(0, 100, 0, 20)
MusicSearchBtn.Position = UDim2.new(0, 6, 0, 58)
MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
MusicSearchBtn.TextColor3 = Color3.new(1, 1, 1)
MusicSearchBtn.Text = "\240\159\148\141 Search"
MusicSearchBtn.Font = Enum.Font.GothamBold
MusicSearchBtn.TextSize = 11
MusicSearchBtn.ZIndex = 2
Instance.new("UICorner", MusicSearchBtn).CornerRadius = UDim.new(0, 5)

local MusicBackBtn = Instance.new("TextButton", MusicBg)
MusicBackBtn.Size = UDim2.new(0, 64, 0, 20)
MusicBackBtn.Position = UDim2.new(0, 110, 0, 58)
MusicBackBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
MusicBackBtn.TextColor3 = Color3.new(1, 1, 1)
MusicBackBtn.Text = "\226\134\144 Back"
MusicBackBtn.Font = Enum.Font.GothamBold
MusicBackBtn.TextSize = 11
MusicBackBtn.Visible = false
MusicBackBtn.ZIndex = 2
Instance.new("UICorner", MusicBackBtn).CornerRadius = UDim.new(0, 5)

local MusicStopBtn = Instance.new("TextButton", MusicBg)
MusicStopBtn.Size = UDim2.new(0, 78, 0, 20)
MusicStopBtn.AnchorPoint = Vector2.new(1, 0)
MusicStopBtn.Position = UDim2.new(1, -6, 0, 58)
MusicStopBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
MusicStopBtn.TextColor3 = Color3.new(1, 1, 1)
MusicStopBtn.Text = "\226\143\185 Stop"
MusicStopBtn.Font = Enum.Font.GothamBold
MusicStopBtn.TextSize = 11
MusicStopBtn.ZIndex = 2
Instance.new("UICorner", MusicStopBtn).CornerRadius = UDim.new(0, 5)

local MusicThumbnail = Instance.new("ImageLabel", MusicBg)
MusicThumbnail.Name             = "MusicThumbnail"
MusicThumbnail.Size             = UDim2.new(1, -12, 0, 80)
MusicThumbnail.Position         = UDim2.new(0, 6, 0, 82)
MusicThumbnail.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MusicThumbnail.ScaleType        = Enum.ScaleType.Crop
MusicThumbnail.Image            = ""
MusicThumbnail.Visible          = false
MusicThumbnail.ZIndex           = 2
Instance.new("UICorner", MusicThumbnail).CornerRadius = UDim.new(0, 7)

local MusicThumbPlaceholder = Instance.new("TextLabel", MusicThumbnail)
MusicThumbPlaceholder.Size             = UDim2.new(1, 0, 1, 0)
MusicThumbPlaceholder.BackgroundTransparency = 1
MusicThumbPlaceholder.Text             = "No Artwork"
MusicThumbPlaceholder.TextColor3       = Color3.fromRGB(70, 70, 70)
MusicThumbPlaceholder.Font             = Enum.Font.Gotham
MusicThumbPlaceholder.TextSize         = 10
MusicThumbPlaceholder.ZIndex           = 3

local MusicResultsPanel = Instance.new("ScrollingFrame", MusicBg)
MusicResultsPanel.Size = UDim2.new(1, -12, 0, 80)
MusicResultsPanel.Position = UDim2.new(0, 6, 0, 82)
MusicResultsPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
MusicResultsPanel.BorderSizePixel = 0
MusicResultsPanel.ScrollBarThickness = 3
MusicResultsPanel.ScrollBarImageColor3 = Color3.fromRGB(255, 85, 0)
MusicResultsPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
MusicResultsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
MusicResultsPanel.Visible = false
MusicResultsPanel.ZIndex = 2
Instance.new("UICorner", MusicResultsPanel).CornerRadius = UDim.new(0, 6)
local MusicResultsLayout = Instance.new("UIListLayout", MusicResultsPanel)
MusicResultsLayout.Padding = UDim.new(0, 2)
MusicResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
local _mrPad = Instance.new("UIPadding", MusicResultsPanel)
_mrPad.PaddingTop = UDim.new(0, 2)
_mrPad.PaddingLeft = UDim.new(0, 2)
_mrPad.PaddingRight = UDim.new(0, 2)
_mrPad.PaddingBottom = UDim.new(0, 2)

local MusicSongTitle = Instance.new("TextLabel", MusicBg)
MusicSongTitle.Size = UDim2.new(1, -12, 0, 13)
MusicSongTitle.Position = UDim2.new(0, 6, 0, 166)
MusicSongTitle.BackgroundTransparency = 1
MusicSongTitle.Text = "No song selected"
MusicSongTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
MusicSongTitle.Font = Enum.Font.GothamMedium
MusicSongTitle.TextSize = 10
MusicSongTitle.TextTruncate = Enum.TextTruncate.AtEnd
MusicSongTitle.TextXAlignment = Enum.TextXAlignment.Left
MusicSongTitle.ZIndex = 2

local MusicSongDuration = Instance.new("TextLabel", MusicBg)
MusicSongDuration.Size = UDim2.new(1, -12, 0, 11)
MusicSongDuration.Position = UDim2.new(0, 6, 0, 180)
MusicSongDuration.BackgroundTransparency = 1
MusicSongDuration.Text = "Duration: 0:00"
MusicSongDuration.TextColor3 = Color3.fromRGB(130, 130, 130)
MusicSongDuration.Font = Enum.Font.Gotham
MusicSongDuration.TextSize = 9
MusicSongDuration.TextXAlignment = Enum.TextXAlignment.Left
MusicSongDuration.ZIndex = 2

local MusicPrevBtn = Instance.new("TextButton", MusicBg)
MusicPrevBtn.Size = UDim2.new(0, 32, 0, 26)
MusicPrevBtn.Position = UDim2.new(0, 6, 0, 194)
MusicPrevBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MusicPrevBtn.TextColor3 = Color3.new(1, 1, 1)
MusicPrevBtn.Text = "\226\143\174"
MusicPrevBtn.Font = Enum.Font.GothamBold
MusicPrevBtn.TextSize = 13
MusicPrevBtn.ZIndex = 2
Instance.new("UICorner", MusicPrevBtn).CornerRadius = UDim.new(0, 5)

local MusicPlayBtn = Instance.new("TextButton", MusicBg)
MusicPlayBtn.Size = UDim2.new(1, -100, 0, 26)
MusicPlayBtn.Position = UDim2.new(0, 42, 0, 194)
MusicPlayBtn.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
MusicPlayBtn.TextColor3 = Color3.new(1, 1, 1)
MusicPlayBtn.Text = "\226\150\182 Play & Broadcast"
MusicPlayBtn.Font = Enum.Font.GothamBold
MusicPlayBtn.TextSize = 11
MusicPlayBtn.ZIndex = 2
Instance.new("UICorner", MusicPlayBtn).CornerRadius = UDim.new(0, 5)

local MusicNextBtn = Instance.new("TextButton", MusicBg)
MusicNextBtn.Size = UDim2.new(0, 32, 0, 26)
MusicNextBtn.AnchorPoint = Vector2.new(1, 0)
MusicNextBtn.Position = UDim2.new(1, -6, 0, 194)
MusicNextBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MusicNextBtn.TextColor3 = Color3.new(1, 1, 1)
MusicNextBtn.Text = "\226\143\173"
MusicNextBtn.Font = Enum.Font.GothamBold
MusicNextBtn.TextSize = 13
MusicNextBtn.ZIndex = 2
Instance.new("UICorner", MusicNextBtn).CornerRadius = UDim.new(0, 5)

local MusicProgressBG = Instance.new("Frame", MusicBg)
MusicProgressBG.Size = UDim2.new(1, -68, 0, 8)
MusicProgressBG.Position = UDim2.new(0, 6, 0, 226)
MusicProgressBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MusicProgressBG.BorderSizePixel = 0
MusicProgressBG.Active = true
MusicProgressBG.Visible = false
MusicProgressBG.ZIndex = 2
Instance.new("UICorner", MusicProgressBG).CornerRadius = UDim.new(1, 0)

local MusicProgressFill = Instance.new("Frame", MusicProgressBG)
MusicProgressFill.Size = UDim2.new(0, 0, 1, 0)
MusicProgressFill.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
MusicProgressFill.BorderSizePixel = 0
MusicProgressFill.ZIndex = 3
Instance.new("UICorner", MusicProgressFill).CornerRadius = UDim.new(1, 0)

local MusicSeekKnob = Instance.new("Frame", MusicProgressBG)
MusicSeekKnob.Name             = "MusicSeekKnob"
MusicSeekKnob.Size             = UDim2.new(0, 12, 0, 12)
MusicSeekKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
MusicSeekKnob.Position         = UDim2.new(0, 0, 0.5, 0)
MusicSeekKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MusicSeekKnob.BorderSizePixel  = 0
MusicSeekKnob.ZIndex           = 4
MusicSeekKnob.Visible          = false
Instance.new("UICorner", MusicSeekKnob).CornerRadius = UDim.new(1, 0)

local MusicShuffleBtn = Instance.new("TextButton", MusicBg)
MusicShuffleBtn.Size             = UDim2.new(0, 28, 0, 18)
MusicShuffleBtn.AnchorPoint      = Vector2.new(1, 0)
MusicShuffleBtn.Position         = UDim2.new(1, -36, 0, 222)
MusicShuffleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MusicShuffleBtn.TextColor3       = Color3.fromRGB(160, 160, 160)
MusicShuffleBtn.Text             = "\240\159\148\128"
MusicShuffleBtn.Font             = Enum.Font.GothamBold
MusicShuffleBtn.TextSize         = 11
MusicShuffleBtn.ZIndex           = 2
Instance.new("UICorner", MusicShuffleBtn).CornerRadius = UDim.new(0, 4)

local MusicLoopBtn = Instance.new("TextButton", MusicBg)
MusicLoopBtn.Size             = UDim2.new(0, 28, 0, 18)
MusicLoopBtn.AnchorPoint      = Vector2.new(1, 0)
MusicLoopBtn.Position         = UDim2.new(1, -6, 0, 222)
MusicLoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MusicLoopBtn.TextColor3       = Color3.fromRGB(160, 160, 160)
MusicLoopBtn.Text             = "\240\159\148\129"
MusicLoopBtn.Font             = Enum.Font.GothamBold
MusicLoopBtn.TextSize         = 11
MusicLoopBtn.ZIndex           = 2
Instance.new("UICorner", MusicLoopBtn).CornerRadius = UDim.new(0, 4)

local MusicTimeLeft = Instance.new("TextLabel", MusicBg)
MusicTimeLeft.Size = UDim2.new(0, 40, 0, 10)
MusicTimeLeft.Position = UDim2.new(0, 6, 0, 236)
MusicTimeLeft.BackgroundTransparency = 1
MusicTimeLeft.Text = "0:00"
MusicTimeLeft.TextColor3 = Color3.fromRGB(110, 110, 110)
MusicTimeLeft.Font = Enum.Font.Gotham
MusicTimeLeft.TextSize = 9
MusicTimeLeft.TextXAlignment = Enum.TextXAlignment.Left
MusicTimeLeft.Visible = false
MusicTimeLeft.ZIndex = 2

local MusicTimeRight = Instance.new("TextLabel", MusicBg)
MusicTimeRight.Size = UDim2.new(0, 40, 0, 10)
MusicTimeRight.AnchorPoint = Vector2.new(1, 0)
MusicTimeRight.Position = UDim2.new(1, -6, 0, 236)
MusicTimeRight.BackgroundTransparency = 1
MusicTimeRight.Text = "0:00"
MusicTimeRight.TextColor3 = Color3.fromRGB(110, 110, 110)
MusicTimeRight.Font = Enum.Font.Gotham
MusicTimeRight.TextSize = 9
MusicTimeRight.TextXAlignment = Enum.TextXAlignment.Right
MusicTimeRight.Visible = false
MusicTimeRight.ZIndex = 2

local MusicVolLabel = Instance.new("TextLabel", MusicBg)
MusicVolLabel.Size             = UDim2.new(0, 70, 0, 13)
MusicVolLabel.AnchorPoint      = Vector2.new(1, 0)
MusicVolLabel.Position         = UDim2.new(1, -6, 0, 3)
MusicVolLabel.BackgroundTransparency = 1
MusicVolLabel.Text             = "Vol: 100%"
MusicVolLabel.TextColor3       = Color3.fromRGB(120, 120, 120)
MusicVolLabel.Font             = Enum.Font.Gotham
MusicVolLabel.TextSize         = 9
MusicVolLabel.TextXAlignment   = Enum.TextXAlignment.Right
MusicVolLabel.ZIndex           = 2

local ReplyBanner = Instance.new("Frame", Main)
ReplyBanner.Size = UDim2.new(1, -14, 0, 16)
ReplyBanner.Position = UDim2.new(0, 7, 1, -76)
ReplyBanner.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
ReplyBanner.BackgroundTransparency = 0.0
ReplyBanner.BorderSizePixel = 0
ReplyBanner.Visible = false
Instance.new("UICorner", ReplyBanner).CornerRadius = UDim.new(0, 5)
local _replyStroke = Instance.new("UIStroke", ReplyBanner)
_replyStroke.Color = Color3.fromRGB(219, 219, 219)
_replyStroke.Thickness = 1

local ReplyLabel = Instance.new("TextLabel", ReplyBanner)
ReplyLabel.Size = UDim2.new(1, -22, 1, 0)
ReplyLabel.Position = UDim2.new(0, 5, 0, 0)
ReplyLabel.BackgroundTransparency = 1
ReplyLabel.RichText = true
ReplyLabel.Text = "Replying to ..."
ReplyLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
ReplyLabel.Font = Enum.Font.Gotham
ReplyLabel.TextSize = 10
ReplyLabel.TextXAlignment = Enum.TextXAlignment.Left
ReplyLabel.TextTruncate = Enum.TextTruncate.AtEnd

local ReplyCloseBtn = Instance.new("TextButton", ReplyBanner)
ReplyCloseBtn.Size = UDim2.new(0, 16, 1, 0)
ReplyCloseBtn.Position = UDim2.new(1, -18, 0, 0)
ReplyCloseBtn.Text = "X"
ReplyCloseBtn.Font = Enum.Font.GothamBold
ReplyCloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
ReplyCloseBtn.BackgroundTransparency = 1
ReplyCloseBtn.TextSize = 10

ReplyCloseBtn.MouseButton1Click:Connect(function()
    ReplyTargetName = nil
    ReplyTargetMsg = nil
    ReplyBanner.Visible = false
    ReplyLabel.Text = "Replying to ..."
end)

local InputArea = Instance.new("Frame", Main)
InputArea.Size = UDim2.new(1, -14, 0, 36)
InputArea.Position = UDim2.new(0, 7, 1, -44)
InputArea.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
InputArea.BackgroundTransparency = 0.0
InputArea.BorderSizePixel = 0
Instance.new("UICorner", InputArea).CornerRadius = UDim.new(0, 10)
local InputStroke = Instance.new("UIStroke", InputArea)
InputStroke.Color = Color3.fromRGB(219, 219, 219)
InputStroke.Thickness = 1
InputStroke.Transparency = 0.0

local Input = Instance.new("TextBox", InputArea)
Input.Size = UDim2.new(1, -44, 1, 0)
Input.Position = UDim2.new(0, 8, 0, 0)
Input.PlaceholderText = "* Type a message..."
Input.BackgroundTransparency = 1
Input.TextColor3 = Color3.fromRGB(0, 0, 0)
Input.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
Input.Font = Enum.Font.Gotham
Input.TextSize = 14
Input.ClearTextOnFocus = true
Input.TextXAlignment = Enum.TextXAlignment.Left

StickerBtn = Instance.new("TextButton", InputArea)
StickerBtn.Size = UDim2.new(0, 28, 0, 28)
StickerBtn.Position = UDim2.new(1, -74, 0.5, -14)
StickerBtn.Text = "\240\159\142\173"
StickerBtn.Font = Enum.Font.GothamBold
StickerBtn.TextColor3 = Color3.fromRGB(80, 80, 80)
StickerBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
StickerBtn.BackgroundTransparency = 0.0
StickerBtn.TextSize = 14
StickerBtn.ZIndex = 3
Instance.new("UICorner", StickerBtn).CornerRadius = UDim.new(1, 0)
local StickerBtnStroke = Instance.new("UIStroke", StickerBtn)
StickerBtnStroke.Color = Color3.fromRGB(200, 200, 200)
StickerBtnStroke.Thickness = 1
StickerBtnStroke.Transparency = 0.0
StickerBtn.MouseButton1Click:Connect(openStickerPanel)

Input.Size = UDim2.new(1, -82, 1, 0)

local SendBtn = Instance.new("TextButton", InputArea)
SendBtn.Size = UDim2.new(0, 32, 0, 26)
SendBtn.Position = UDim2.new(1, -38, 0.5, -13)
SendBtn.Text = ">>"
SendBtn.Font = Enum.Font.GothamBold
SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SendBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
SendBtn.BackgroundTransparency = 0.0
SendBtn.TextSize = 14
Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(0, 8)

local CharCounter = Instance.new("TextLabel", Main)
CharCounter.Size = UDim2.new(0, 60, 0, 16)
CharCounter.Position = UDim2.new(1, -68, 1, -62)
CharCounter.BackgroundTransparency = 1
CharCounter.Text = "200"
CharCounter.TextColor3 = Color3.fromRGB(120, 120, 120)
CharCounter.Font = Enum.Font.GothamBold
CharCounter.TextSize = 11
CharCounter.TextXAlignment = Enum.TextXAlignment.Right
CharCounter.ZIndex = 5
CharCounter.Visible = false

Input:GetPropertyChangedSignal("Text"):Connect(function()
    local len = #Input.Text
    local remaining = MAX_CHAR_LIMIT - len
    if len == 0 then
        CharCounter.Visible = false
    else
        CharCounter.Visible = true
        CharCounter.Text = tostring(remaining)
        if remaining <= 20 then
            CharCounter.TextColor3 = Color3.fromRGB(220, 50, 50)
        elseif remaining <= 50 then
            CharCounter.TextColor3 = Color3.fromRGB(200, 140, 30)
        else
            CharCounter.TextColor3 = Color3.fromRGB(120, 120, 120)
        end
    end

    if len > MAX_CHAR_LIMIT then
        Input.Text = string.sub(Input.Text, 1, MAX_CHAR_LIMIT)
        Input.CursorPosition = MAX_CHAR_LIMIT + 1
    end
end)

local PvtInputTag = Instance.new("TextButton", InputArea)
PvtInputTag.Size = UDim2.new(0, 66, 0, 28)
PvtInputTag.Position = UDim2.new(0, 3, 0.5, -14)
PvtInputTag.BackgroundColor3 = Color3.fromRGB(255, 230, 245)
PvtInputTag.BackgroundTransparency = 0.0
PvtInputTag.Text = "[...]"
PvtInputTag.Font = Enum.Font.GothamBold
PvtInputTag.TextColor3 = Color3.fromRGB(180, 30, 100)
PvtInputTag.TextSize = 11
PvtInputTag.TextTruncate = Enum.TextTruncate.AtEnd
PvtInputTag.Visible = false
PvtInputTag.ZIndex = 4
Instance.new("UICorner", PvtInputTag).CornerRadius = UDim.new(0, 7)
local PvtInputTagStroke = Instance.new("UIStroke", PvtInputTag)
PvtInputTagStroke.Color = Color3.fromRGB(225, 48, 108)
PvtInputTagStroke.Thickness = 1
PvtInputTagStroke.Transparency = 0.2

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 56, 0, 56)
ToggleBtn.Position = UDim2.new(0, 6, 0.72, 0)
ToggleBtn.AnchorPoint = Vector2.new(0, 0.5)
ToggleBtn.Text = "*"
ToggleBtn.TextSize = 22
ToggleBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
ToggleBtn.BackgroundTransparency = 0.0
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Active = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Thickness = 2.0
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Transparency = 0.6

task.spawn(function()
    while ToggleBtn and ToggleBtn.Parent do
        ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
        task.wait(1)
    end
end)

local function clearPvt()
    PrivateTargetId = nil
    PrivateTargetName = nil
    Input.PlaceholderText = "* Type a message..."
    InputArea.BackgroundColor3 = Color3.fromRGB(250, 250, 250)

    PvtInputTag.Visible = false
    Input.Position = UDim2.new(0, 8, 0, 0)
    Input.Size = UDim2.new(1, -44, 1, 0)
end

PvtInputTag.MouseButton1Click:Connect(clearPvt)

local MsgPopup = Instance.new("Frame", ScreenGui)
MsgPopup.Name        = "MsgContextPopup"
MsgPopup.Size        = UDim2.new(0, 168, 0, 0)
MsgPopup.AutomaticSize = Enum.AutomaticSize.Y
MsgPopup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MsgPopup.BackgroundTransparency = 0.0
MsgPopup.BorderSizePixel = 0
MsgPopup.Visible     = false
MsgPopup.ZIndex      = 200
MsgPopup.ClipsDescendants = true
local _popCorner = Instance.new("UICorner", MsgPopup)
_popCorner.CornerRadius = UDim.new(0, 16)
local _popStroke = Instance.new("UIStroke", MsgPopup)
_popStroke.Color       = Color3.fromRGB(225, 48, 108)
_popStroke.Thickness   = 1.4
_popStroke.Transparency = 0.0
local _popList = Instance.new("UIListLayout", MsgPopup)
_popList.Padding       = UDim.new(0, 0)
_popList.SortOrder     = Enum.SortOrder.LayoutOrder
local _popPad = Instance.new("UIPadding", MsgPopup)
_popPad.PaddingTop    = UDim.new(0, 6)
_popPad.PaddingBottom = UDim.new(0, 6)

local function closeMsgPopup()
    if not MsgPopup.Visible then return end
    TweenService:Create(MsgPopup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {BackgroundTransparency = 1}):Play()
    task.delay(0.13, function()
        MsgPopup.Visible = false
        MsgPopup.BackgroundTransparency = 0.0
        for _, c in pairs(MsgPopup:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") and c.Name == "PopItem" then
                c:Destroy()
            end
        end
    end)
end

local function addPopupItem(icon, label, order, isDestructive, callback)
    local item = Instance.new("TextButton", MsgPopup)
    item.Name             = "PopItem"
    item.Size             = UDim2.new(1, 0, 0, 44)
    item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    item.BackgroundTransparency = 1
    item.Text             = ""
    item.LayoutOrder      = order
    item.ZIndex           = 201
    item.ClipsDescendants = false

    local iconL = Instance.new("TextLabel", item)
    iconL.Size     = UDim2.new(0, 38, 1, 0)
    iconL.Position = UDim2.new(0, 10, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text     = icon
    iconL.TextSize = 17
    iconL.Font     = Enum.Font.GothamBold
    iconL.TextColor3 = isDestructive and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(30, 30, 30)
    iconL.TextXAlignment = Enum.TextXAlignment.Center
    iconL.ZIndex   = 202

    local textL = Instance.new("TextLabel", item)
    textL.Size     = UDim2.new(1, -58, 1, 0)
    textL.Position = UDim2.new(0, 50, 0, 0)
    textL.BackgroundTransparency = 1
    textL.Text     = label
    textL.Font     = Enum.Font.GothamSemibold
    textL.TextSize = 13
    textL.TextColor3 = isDestructive and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(30, 30, 30)
    textL.TextXAlignment = Enum.TextXAlignment.Left
    textL.ZIndex   = 202

    local div = Instance.new("Frame", item)
    div.Name              = "Divider"
    div.Size              = UDim2.new(1, -20, 0, 1)
    div.Position          = UDim2.new(0, 10, 1, -1)
    div.BackgroundColor3  = Color3.fromRGB(219, 219, 219)
    div.BackgroundTransparency = 0.0
    div.BorderSizePixel   = 0
    div.ZIndex            = 202

    item.MouseEnter:Connect(function()
        TweenService:Create(item, TweenInfo.new(0.1), {BackgroundTransparency = 0.88}):Play()
        item.BackgroundColor3 = isDestructive and Color3.fromRGB(255, 230, 230) or Color3.fromRGB(230, 230, 230)
    end)
    item.MouseLeave:Connect(function()
        TweenService:Create(item, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
    end)

    item.MouseButton1Click:Connect(function()
        closeMsgPopup()
        task.spawn(callback)
    end)

    return item
end

local function showMsgPopup(screenPos, options)

    for _, c in pairs(MsgPopup:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    for i, opt in ipairs(options) do
        addPopupItem(opt.icon, opt.label, i, opt.destructive or false, opt.callback)
    end

    local items = {}
    for _, c in pairs(MsgPopup:GetChildren()) do
        if c:IsA("TextButton") then table.insert(items, c) end
    end
    table.sort(items, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    if items[#items] then
        local lastDiv = items[#items]:FindFirstChild("Divider")
        if lastDiv then lastDiv.BackgroundTransparency = 1 end
    end

    local vpSize  = game.Workspace.CurrentCamera.ViewportSize
    local popW, popH = 168, #options * 44 + 12
    local mainAbs = Main.AbsolutePosition
    local mainSz  = Main.AbsoluteSize
    local guiLeft   = mainAbs.X + 4
    local guiRight  = mainAbs.X + mainSz.X - popW - 4
    local guiTop    = mainAbs.Y + 4
    local guiBottom = mainAbs.Y + mainSz.Y - popH - 4
    local px = math.clamp(screenPos.X - popW / 2, guiLeft, math.max(guiLeft, guiRight))
    local py = screenPos.Y - popH - 10
    if py < guiTop then py = screenPos.Y + 10 end
    py = math.clamp(py, guiTop, math.max(guiTop, guiBottom))

    MsgPopup.Position = UDim2.new(0, px, 0, py)
    MsgPopup.BackgroundTransparency = 1
    MsgPopup.Visible  = true
    TweenService:Create(MsgPopup, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.0}):Play()
end

UserInputService.InputBegan:Connect(function(inp)
    if not MsgPopup.Visible then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
    local p   = inp.Position
    local abs = MsgPopup.AbsolutePosition
    local sz  = MsgPopup.AbsoluteSize
    if p.X < abs.X or p.X > abs.X + sz.X or p.Y < abs.Y or p.Y > abs.Y + sz.Y then
        closeMsgPopup()
    end
end)

local followStateCache = {}
local followerCountCache = {}
local followingCountCache = {}
local showProfilePage
local addMessage

local function getProfileNameFromCache(uid, profiles)
    uid = tonumber(uid)
    if not uid then return "User" end
    local pdata = profiles and profiles[tostring(uid)]
    if type(pdata) == "table" then
        return tostring(pdata.displayName or pdata.username or ("User " .. tostring(uid)))
    end
    local plr = Players:GetPlayerByUserId(uid)
    if plr then return plr.DisplayName end
    local ok, name = pcall(function()
        return Players:GetNameFromUserIdAsync(uid)
    end)
    if ok and name and name ~= "" then return tostring(name) end
    return "User " .. tostring(uid)
end

local function loadProfileNames(req)
    local profiles = {}
    if not req then return profiles end
    pcall(function()
        local res = req({ Url = PROFILES_URL .. ".json", Method = "GET" })
        if res and res.Success and res.Body ~= "null" then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok and type(data) == "table" then profiles = data end
        end
    end)
    return profiles
end

local function showFollowListOverlay(targetUid, targetDisplayName, mode)
    local req = syn and syn.request or http and http.request or request
    if not req or not targetUid then return end

    local listOverlay = Instance.new("Frame", ScreenGui)
    listOverlay.Size = Main.Size
    listOverlay.Position = Main.Position
    listOverlay.AnchorPoint = Main.AnchorPoint
    listOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    listOverlay.BackgroundTransparency = 0.0
    listOverlay.BorderSizePixel = 0
    listOverlay.ZIndex = 650
    listOverlay.ClipsDescendants = true
    Instance.new("UICorner", listOverlay).CornerRadius = UDim.new(0, 16)
    local listStroke = Instance.new("UIStroke", listOverlay)
    listStroke.Color = Color3.fromRGB(225, 48, 108)
    listStroke.Thickness = 1.5

    local listBack = Instance.new("TextButton", listOverlay)
    listBack.Size = UDim2.new(0, 30, 0, 30)
    listBack.Position = UDim2.new(0, 8, 0, 6)
    listBack.Text = "\226\134\144"
    listBack.Font = Enum.Font.GothamBold
    listBack.TextSize = 18
    listBack.TextColor3 = Color3.fromRGB(50, 50, 50)
    listBack.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
    listBack.ZIndex = 651
    Instance.new("UICorner", listBack).CornerRadius = UDim.new(1, 0)
    listBack.MouseButton1Click:Connect(function()
        if listOverlay and listOverlay.Parent then listOverlay:Destroy() end
    end)

    local title = Instance.new("TextLabel", listOverlay)
    title.Size = UDim2.new(1, -54, 0, 30)
    title.Position = UDim2.new(0, 44, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = tostring(targetDisplayName or "User") .. " " .. (mode == "following" and "Following" or "Followers")
    title.TextColor3 = Color3.fromRGB(0, 0, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 651

    local divider = Instance.new("Frame", listOverlay)
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 40)
    divider.BackgroundColor3 = Color3.fromRGB(219, 219, 219)
    divider.BorderSizePixel = 0
    divider.ZIndex = 651

    local listLog = Instance.new("ScrollingFrame", listOverlay)
    listLog.Size = UDim2.new(1, -14, 1, -48)
    listLog.Position = UDim2.new(0, 7, 0, 44)
    listLog.BackgroundTransparency = 1
    listLog.ScrollBarThickness = 3
    listLog.ScrollBarImageColor3 = Color3.fromRGB(225, 48, 108)
    listLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listLog.ZIndex = 651
    local listLayout = Instance.new("UIListLayout", listLog)
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local loading = Instance.new("TextLabel", listLog)
    loading.Size = UDim2.new(1, 0, 0, 36)
    loading.BackgroundTransparency = 1
    loading.Text = "Loading..."
    loading.TextColor3 = Color3.fromRGB(160, 160, 160)
    loading.Font = Enum.Font.Gotham
    loading.TextSize = 12
    loading.ZIndex = 652

    task.spawn(function()
        local allFollowers = {}
        local profiles = loadProfileNames(req)
        pcall(function()
            local res = req({ Url = FOLLOWERS_URL .. ".json", Method = "GET" })
            if res and res.Success and res.Body ~= "null" then
                local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok and type(data) == "table" then allFollowers = data end
            end
        end)

        local uidStr = tostring(targetUid)
        local rows = {}
        if mode == "following" then
            for followedUid, followers in pairs(allFollowers) do
                if type(followers) == "table" and followers[uidStr] then
                    local fuid = tonumber(followedUid)
                    if fuid then table.insert(rows, fuid) end
                end
            end
        else
            local followers = allFollowers[uidStr]
            if type(followers) == "table" then
                for followerUid, _ in pairs(followers) do
                    local fuid = tonumber(followerUid)
                    if fuid then table.insert(rows, fuid) end
                end
            end
        end
        table.sort(rows, function(a, b)
            return getProfileNameFromCache(a, profiles) < getProfileNameFromCache(b, profiles)
        end)

        if loading and loading.Parent then loading:Destroy() end
        if #rows == 0 then
            local empty = Instance.new("TextLabel", listLog)
            empty.Size = UDim2.new(1, 0, 0, 42)
            empty.BackgroundTransparency = 1
            empty.Text = mode == "following" and "Not following anyone yet." or "No followers yet."
            empty.TextColor3 = Color3.fromRGB(160, 160, 160)
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.ZIndex = 652
            return
        end

        for _, uid in ipairs(rows) do
            local rowName = getProfileNameFromCache(uid, profiles)
            local row = Instance.new("TextButton", listLog)
            row.Size = UDim2.new(1, -4, 0, 48)
            row.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            row.BackgroundTransparency = 0.0
            row.BorderSizePixel = 0
            row.Text = ""
            row.AutoButtonColor = true
            row.ZIndex = 652
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color = Color3.fromRGB(219, 219, 219)
            rowStroke.Thickness = 1

            local img = Instance.new("ImageLabel", row)
            img.Size = UDim2.new(0, 34, 0, 34)
            img.Position = UDim2.new(0, 8, 0.5, -17)
            img.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            img.BorderSizePixel = 0
            img.ZIndex = 653
            Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
            task.spawn(function()
                pcall(function()
                    local content, ready = Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                    if ready and img and img.Parent then img.Image = content end
                end)
            end)

            local lbl = Instance.new("TextLabel", row)
            lbl.Size = UDim2.new(1, -56, 1, 0)
            lbl.Position = UDim2.new(0, 50, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = rowName
            lbl.TextColor3 = Color3.fromRGB(0, 0, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = 653

            row.MouseButton1Click:Connect(function()
                if showProfilePage then showProfilePage(uid, rowName, rowName) end
            end)
        end
    end)
end

showProfilePage = function(targetUid, targetDisplayName, targetUsername)
    if not targetUid or targetUid == 0 then return end

    local overlay = Instance.new("Frame", ScreenGui)
    overlay.Size = Main.Size
    overlay.Position = Main.Position
    overlay.AnchorPoint = Main.AnchorPoint
    overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    overlay.BackgroundTransparency = 0.0
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 500
    overlay.ClipsDescendants = true
    local ovCorner = Instance.new("UICorner", overlay)
    ovCorner.CornerRadius = UDim.new(0, 16)
    local ovStroke = Instance.new("UIStroke", overlay)
    ovStroke.Color = Color3.fromRGB(225, 48, 108)
    ovStroke.Thickness = 1.5
    ovStroke.Transparency = 0.0

    overlay.Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset + 380,
                                  Main.Position.Y.Scale, Main.Position.Y.Offset)
    TweenService:Create(overlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = Main.Position}):Play()

    local backBtn = Instance.new("TextButton", overlay)
    backBtn.Size = UDim2.new(0, 30, 0, 30)
    backBtn.Position = UDim2.new(0, 8, 0, 6)
    backBtn.Text = "\226\134\144"
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextSize = 18
    backBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
    backBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
    backBtn.BackgroundTransparency = 0.0
    backBtn.ZIndex = 501
    Instance.new("UICorner", backBtn).CornerRadius = UDim.new(1, 0)
    backBtn.MouseButton1Click:Connect(function()
        TweenService:Create(overlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset + 380,
                                   Main.Position.Y.Scale, Main.Position.Y.Offset)}):Play()
        task.delay(0.2, function() if overlay and overlay.Parent then overlay:Destroy() end end)
    end)

    local profileTitle = Instance.new("TextLabel", overlay)
    profileTitle.Size = UDim2.new(1, -50, 0, 30)
    profileTitle.Position = UDim2.new(0, 44, 0, 6)
    profileTitle.BackgroundTransparency = 1
    profileTitle.Text = "Profile"
    profileTitle.TextColor3 = Color3.fromRGB(0, 0, 0)
    profileTitle.Font = Enum.Font.GothamBold
    profileTitle.TextSize = 14
    profileTitle.TextXAlignment = Enum.TextXAlignment.Left
    profileTitle.ZIndex = 501

    local profDivider = Instance.new("Frame", overlay)
    profDivider.Size = UDim2.new(1, 0, 0, 1)
    profDivider.Position = UDim2.new(0, 0, 0, 40)
    profDivider.BackgroundColor3 = Color3.fromRGB(219, 219, 219)
    profDivider.BorderSizePixel = 0
    profDivider.ZIndex = 501

    local pfpCircle = Instance.new("Frame", overlay)
    pfpCircle.Size = UDim2.new(0, 72, 0, 72)
    pfpCircle.Position = UDim2.new(0, 14, 0, 52)
    pfpCircle.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    pfpCircle.BorderSizePixel = 0
    pfpCircle.ZIndex = 501
    Instance.new("UICorner", pfpCircle).CornerRadius = UDim.new(1, 0)
    local pfpStroke = Instance.new("UIStroke", pfpCircle)
    pfpStroke.Color = Color3.fromRGB(225, 48, 108)
    pfpStroke.Thickness = 2
    pfpStroke.Transparency = 0.0

    local pfpImg = Instance.new("ImageLabel", pfpCircle)
    pfpImg.Size = UDim2.new(1, 0, 1, 0)
    pfpImg.BackgroundTransparency = 1
    pfpImg.ZIndex = 502
    Instance.new("UICorner", pfpImg).CornerRadius = UDim.new(1, 0)

    local followerBox = Instance.new("TextButton", overlay)
    followerBox.Size = UDim2.new(0, 70, 0, 44)
    followerBox.Position = UDim2.new(1, -160, 0, 54)
    followerBox.BackgroundTransparency = 1
    followerBox.Text = ""
    followerBox.AutoButtonColor = false
    followerBox.ZIndex = 501

    local followerCount = Instance.new("TextLabel", followerBox)
    followerCount.Size = UDim2.new(1, 0, 0, 24)
    followerCount.Position = UDim2.new(0, 0, 0, 0)
    followerCount.BackgroundTransparency = 1
    followerCount.Text = "\226\128\148"
    followerCount.TextColor3 = Color3.fromRGB(0, 0, 0)
    followerCount.Font = Enum.Font.GothamBold
    followerCount.TextSize = 18
    followerCount.TextXAlignment = Enum.TextXAlignment.Center
    followerCount.ZIndex = 502

    local followerLabel = Instance.new("TextLabel", followerBox)
    followerLabel.Size = UDim2.new(1, 0, 0, 16)
    followerLabel.Position = UDim2.new(0, 0, 0, 26)
    followerLabel.BackgroundTransparency = 1
    followerLabel.Text = "Followers"
    followerLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    followerLabel.Font = Enum.Font.Gotham
    followerLabel.TextSize = 11
    followerLabel.TextXAlignment = Enum.TextXAlignment.Center
    followerLabel.ZIndex = 502

    local followingBox = Instance.new("TextButton", overlay)
    followingBox.Size = UDim2.new(0, 70, 0, 44)
    followingBox.Position = UDim2.new(1, -82, 0, 54)
    followingBox.BackgroundTransparency = 1
    followingBox.Text = ""
    followingBox.AutoButtonColor = false
    followingBox.ZIndex = 501

    local followingCount = Instance.new("TextLabel", followingBox)
    followingCount.Size = UDim2.new(1, 0, 0, 24)
    followingCount.Position = UDim2.new(0, 0, 0, 0)
    followingCount.BackgroundTransparency = 1
    followingCount.Text = "\226\128\148"
    followingCount.TextColor3 = Color3.fromRGB(0, 0, 0)
    followingCount.Font = Enum.Font.GothamBold
    followingCount.TextSize = 18
    followingCount.TextXAlignment = Enum.TextXAlignment.Center
    followingCount.ZIndex = 502

    local followingLabel = Instance.new("TextLabel", followingBox)
    followingLabel.Size = UDim2.new(1, 0, 0, 16)
    followingLabel.Position = UDim2.new(0, 0, 0, 26)
    followingLabel.BackgroundTransparency = 1
    followingLabel.Text = "Following"
    followingLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    followingLabel.Font = Enum.Font.Gotham
    followingLabel.TextSize = 11
    followingLabel.TextXAlignment = Enum.TextXAlignment.Center
    followingLabel.ZIndex = 502

    followerBox.MouseButton1Click:Connect(function()
        showFollowListOverlay(targetUid, targetDisplayName, "followers")
    end)
    followingBox.MouseButton1Click:Connect(function()
        showFollowListOverlay(targetUid, targetDisplayName, "following")
    end)

    local displayNameLabel = Instance.new("TextLabel", overlay)
    displayNameLabel.Size = UDim2.new(1, -24, 0, 22)
    displayNameLabel.Position = UDim2.new(0, 14, 0, 132)
    displayNameLabel.BackgroundTransparency = 1
    displayNameLabel.RichText = true
    displayNameLabel.Text = "<b>" .. targetDisplayName .. "</b>"
    displayNameLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    displayNameLabel.Font = Enum.Font.GothamBold
    displayNameLabel.TextSize = 16
    displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    displayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    displayNameLabel.ZIndex = 502

    local function applyProfileTitle(fTitleType, hasTag)
        if not displayNameLabel or not displayNameLabel.Parent then return end
        if not fTitleType or hasTag then

            displayNameLabel.Text = "<b>" .. targetDisplayName .. "</b>"
        elseif fTitleType == "VIP" then

            displayNameLabel.Text = "<font color='rgb(220,160,0)'><b>[VIP]</b></font> <b>" .. targetDisplayName .. "</b>"
        elseif fTitleType == "Legend" then

            displayNameLabel.Text = "<font color='rgb(220,30,30)'><b>[Legend]</b></font> <b>" .. targetDisplayName .. "</b>"
        elseif fTitleType == "Premium" then

            displayNameLabel.Text = "<font color='rgb(100,185,255)'><b>[Premium]</b></font> <b>" .. targetDisplayName .. "</b>"
        end
    end

    local usernameLabel = Instance.new("TextLabel", overlay)
    usernameLabel.Size = UDim2.new(1, -24, 0, 18)
    usernameLabel.Position = UDim2.new(0, 14, 0, 156)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = "@" .. (targetUsername or targetDisplayName)
    usernameLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.TextSize = 12
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.ZIndex = 501

    local btnDivider = Instance.new("Frame", overlay)
    btnDivider.Size = UDim2.new(1, -28, 0, 1)
    btnDivider.Position = UDim2.new(0, 14, 0, 204)
    btnDivider.BackgroundColor3 = Color3.fromRGB(219, 219, 219)
    btnDivider.BorderSizePixel = 0
    btnDivider.ZIndex = 501

    local followBtn = Instance.new("TextButton", overlay)
    followBtn.Size = UDim2.new(1, -28, 0, 36)
    followBtn.Position = UDim2.new(0, 14, 0, 212)
    followBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
    followBtn.BackgroundTransparency = 0.0
    followBtn.BorderSizePixel = 0
    followBtn.Text = "Follow"
    followBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    followBtn.Font = Enum.Font.GothamBold
    followBtn.TextSize = 14
    followBtn.ZIndex = 501
    Instance.new("UICorner", followBtn).CornerRadius = UDim.new(0, 8)

    local isFollowing = false
    local function updateFollowBtn(following)
        isFollowing = following
        if following then
            followBtn.Text = "Following \226\156\147"
            followBtn.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
            followBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
        else
            followBtn.Text = "Follow"
            followBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
            followBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        followStateCache[targetUid] = following
    end

    followBtn.MouseButton1Click:Connect(function()

        if LocalPlayer.AccountAge < 7 then
            addMessage("SYSTEM", "DON'T USE FAKE ACCOUNTS TO FOLLOW\240\159\152\161", true, 0, 0, false, true)
            return
        end
        local req = syn and syn.request or http and http.request or request
        if not req then return end
        local myUidStr = tostring(RealUserId)
        local targetUidStr = tostring(targetUid)
        if isFollowing then

            pcall(function()
                req({ Url = FOLLOWERS_URL .. "/" .. targetUidStr .. "/" .. myUidStr .. ".json", Method = "DELETE" })
            end)
            updateFollowBtn(false)

            followerCountCache[targetUid] = math.max(0, (followerCountCache[targetUid] or 1) - 1)
            followerCount.Text = tostring(followerCountCache[targetUid])
        else

            pcall(function()
                req({ Url = FOLLOWERS_URL .. "/" .. targetUidStr .. "/" .. myUidStr .. ".json",
                      Method = "PUT", Body = HttpService:JSONEncode(true) })

                req({ Url = PROFILES_URL .. "/" .. targetUidStr .. "/displayName.json",
                      Method = "PUT", Body = HttpService:JSONEncode(targetDisplayName) })
                req({ Url = PROFILES_URL .. "/" .. targetUidStr .. "/username.json",
                      Method = "PUT", Body = HttpService:JSONEncode(targetUsername or targetDisplayName) })
            end)
            updateFollowBtn(true)
            followerCountCache[targetUid] = (followerCountCache[targetUid] or 0) + 1
            followerCount.Text = tostring(followerCountCache[targetUid])
        end

        local fc = followerCountCache[targetUid] or 0
        badgeCache[targetUid] = fc
        local fTitleType = getFollowerTitleTypeFromCount(fc)
        local hasTag = (CREATOR_IDS[targetUid] or targetUid == OWNER_ID
            or CUTE_IDS[targetUid] or HELLGOD_IDS[targetUid]
            or VIP_IDS[targetUid] or GRANDFATHER_IDS[targetUid]
            or DADDY_IDS[targetUid] or CustomTitles[targetUid])
        applyProfileTitle(fTitleType, hasTag)
    end)

    task.spawn(function()

        pcall(function()
            local content, ready = Players:GetUserThumbnailAsync(targetUid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
            if ready and pfpImg and pfpImg.Parent then pfpImg.Image = content end
        end)

        local req = syn and syn.request or http and http.request or request
        if not req then return end
        local targetUidStr = tostring(targetUid)
        local myUidStr = tostring(RealUserId)

        pcall(function()
            local res = req({ Url = FOLLOWERS_URL .. "/" .. targetUidStr .. ".json", Method = "GET" })
            if res and res.Success and res.Body ~= "null" then
                local ok, fdata = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok and type(fdata) == "table" then
                    local count = 0
                    for _ in pairs(fdata) do count = count + 1 end
                    followerCountCache[targetUid] = count
                    if followerCount and followerCount.Parent then
                        followerCount.Text = tostring(count)
                    end

                    badgeCache[targetUid] = count
                    local fTitleType2 = getFollowerTitleTypeFromCount(count)
                    local hasTag2 = (CREATOR_IDS[targetUid] or targetUid == OWNER_ID
                        or CUTE_IDS[targetUid] or HELLGOD_IDS[targetUid]
                        or VIP_IDS[targetUid] or GRANDFATHER_IDS[targetUid]
                        or DADDY_IDS[targetUid] or CustomTitles[targetUid])
                    applyProfileTitle(fTitleType2, hasTag2)
                else
                    followerCountCache[targetUid] = 0
                    if followerCount and followerCount.Parent then
                        followerCount.Text = "0"
                    end
                end
            else
                followerCountCache[targetUid] = 0
                if followerCount and followerCount.Parent then
                    followerCount.Text = "0"
                end
            end
        end)

        pcall(function()
            local res = req({ Url = FOLLOWERS_URL .. ".json", Method = "GET" })
            local count = 0
            if res and res.Success and res.Body ~= "null" then
                local ok, allData = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok and type(allData) == "table" then
                    for _, followers in pairs(allData) do
                        if type(followers) == "table" and followers[targetUidStr] then
                            count = count + 1
                        end
                    end
                end
            end
            followingCountCache[targetUid] = count
            if followingCount and followingCount.Parent then
                followingCount.Text = tostring(count)
            end
        end)

        pcall(function()
            local res = req({ Url = FOLLOWERS_URL .. "/" .. targetUidStr .. "/" .. myUidStr .. ".json", Method = "GET" })
            local following = (res and res.Success and res.Body ~= "null" and res.Body ~= "false")
            if followBtn and followBtn.Parent then
                updateFollowBtn(following)
            end
        end)
    end)
end

function RefreshLeaderboard()
    for _, child in pairs(LeaderboardLog:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    local loadingLbl = Instance.new("TextLabel", LeaderboardLog)
    loadingLbl.Size = UDim2.new(1, 0, 0, 30)
    loadingLbl.BackgroundTransparency = 1
    loadingLbl.Text = "Loading leaderboard..."
    loadingLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    loadingLbl.Font = Enum.Font.Gotham
    loadingLbl.TextSize = 12

    task.spawn(function()
        local req = syn and syn.request or http and http.request or request
        if not req then
            if loadingLbl and loadingLbl.Parent then loadingLbl:Destroy() end
            return
        end

        local allFollowers = {}
        pcall(function()
            local res = req({ Url = FOLLOWERS_URL .. ".json", Method = "GET" })
            if res and res.Success and res.Body ~= "null" then
                local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok and type(data) == "table" then
                    for uidStr, followers in pairs(data) do
                        local uid = tonumber(uidStr)
                        if uid and type(followers) == "table" then
                            local count = 0
                            for _ in pairs(followers) do count = count + 1 end
                            if count > 0 then
                                allFollowers[uid] = count
                            end
                        end
                    end
                end
            end
        end)

        local profileNames = {}
        pcall(function()
            local res = req({ Url = PROFILES_URL .. ".json", Method = "GET" })
            if res and res.Success and res.Body ~= "null" then
                local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok and type(data) == "table" then
                    for uidStr, pdata in pairs(data) do
                        local uid = tonumber(uidStr)
                        if uid and type(pdata) == "table" then
                            profileNames[uid] = pdata.displayName or pdata.username or ("User " .. uidStr)
                        end
                    end
                end
            end
        end)

        if loadingLbl and loadingLbl.Parent then loadingLbl:Destroy() end
        for _, child in pairs(LeaderboardLog:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end

        local sorted = {}
        for uid, count in pairs(allFollowers) do
            table.insert(sorted, { uid = uid, count = count })
        end
        table.sort(sorted, function(a, b) return a.count > b.count end)

        if #sorted == 0 then
            local emptyLbl = Instance.new("TextLabel", LeaderboardLog)
            emptyLbl.Size = UDim2.new(1, 0, 0, 40)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Text = "No followers data yet."
            emptyLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
            emptyLbl.Font = Enum.Font.Gotham
            emptyLbl.TextSize = 12
            return
        end

        local headerLbl = Instance.new("TextLabel", LeaderboardLog)
        headerLbl.Size = UDim2.new(1, 0, 0, 24)
        headerLbl.BackgroundTransparency = 1
        headerLbl.Text = "\240\159\143\134  Top Followers Leaderboard"
        headerLbl.TextColor3 = Color3.fromRGB(225, 48, 108)
        headerLbl.Font = Enum.Font.GothamBold
        headerLbl.TextSize = 13
        headerLbl.TextXAlignment = Enum.TextXAlignment.Left

        for rank, entry in ipairs(sorted) do
            local uid = entry.uid
            local count = entry.count
            local displayName = profileNames[uid] or ("User " .. tostring(uid))

            local row = Instance.new("Frame", LeaderboardLog)
            row.Size = UDim2.new(1, -4, 0, 46)
            row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            row.BackgroundTransparency = 0.0
            row.BorderSizePixel = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color = Color3.fromRGB(219, 219, 219)
            rowStroke.Thickness = 1

            local rankLbl = Instance.new("TextLabel", row)
            rankLbl.Size = UDim2.new(0, 28, 1, 0)
            rankLbl.Position = UDim2.new(0, 4, 0, 0)
            rankLbl.BackgroundTransparency = 1
            rankLbl.Text = tostring(rank)
            rankLbl.TextColor3 = rank == 1 and Color3.fromRGB(255, 180, 0)
                              or rank == 2 and Color3.fromRGB(180, 180, 180)
                              or rank == 3 and Color3.fromRGB(180, 100, 50)
                              or Color3.fromRGB(120, 120, 120)
            rankLbl.Font = Enum.Font.GothamBold
            rankLbl.TextSize = 14
            rankLbl.TextXAlignment = Enum.TextXAlignment.Center

            local lbPfp = Instance.new("ImageButton", row)
            lbPfp.Size = UDim2.new(0, 32, 0, 32)
            lbPfp.Position = UDim2.new(0, 34, 0.5, -16)
            lbPfp.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            lbPfp.BorderSizePixel = 0
            lbPfp.AutoButtonColor = false
            Instance.new("UICorner", lbPfp).CornerRadius = UDim.new(1, 0)
            lbPfp.MouseButton1Click:Connect(function()
                showProfilePage(uid, displayName, displayName)
            end)
            task.spawn(function()
                pcall(function()
                    local content, ready = Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                    if ready and lbPfp and lbPfp.Parent then lbPfp.Image = content end
                end)
            end)

            local lbHasTag = (CREATOR_IDS[uid] or uid == OWNER_ID
                or CUTE_IDS[uid] or HELLGOD_IDS[uid]
                or VIP_IDS[uid] or GRANDFATHER_IDS[uid]
                or DADDY_IDS[uid] or CustomTitles[uid])
            local lbTitleType = getFollowerTitleTypeFromCount(count)
            local lbTitleColor
            if lbTitleType == "VIP" then
                lbTitleColor = "rgb(220,160,0)"
            elseif lbTitleType == "Legend" then
                lbTitleColor = "rgb(220,30,30)"
            elseif lbTitleType == "Premium" then
                lbTitleColor = "rgb(0,120,220)"
            end

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -140, 1, 0)
            nameLbl.Position = UDim2.new(0, 72, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.RichText = true
            nameLbl.TextColor3 = Color3.fromRGB(0, 0, 0)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 13
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            if lbTitleType and not lbHasTag and lbTitleColor then
                nameLbl.Text = displayName .. " <font color='" .. lbTitleColor .. "'>[" .. lbTitleType .. "]</font>"
            else
                nameLbl.Text = displayName
            end

            local countPill = Instance.new("TextLabel", row)
            countPill.Size = UDim2.new(0, 62, 0, 22)
            countPill.Position = UDim2.new(1, -68, 0.5, -11)
            countPill.BackgroundColor3 = Color3.fromRGB(255, 230, 240)
            countPill.BackgroundTransparency = 0.0
            countPill.BorderSizePixel = 0
            countPill.Text = tostring(count) .. " \240\159\145\165"
            countPill.TextColor3 = Color3.fromRGB(225, 48, 108)
            countPill.Font = Enum.Font.GothamBold
            countPill.TextSize = 11
            countPill.TextXAlignment = Enum.TextXAlignment.Center
            Instance.new("UICorner", countPill).CornerRadius = UDim.new(0, 11)
        end
    end)
end

local function GetPlaceName(id)
    local success, info = pcall(function() return MarketplaceService:GetProductInfo(id) end)
    return success and info.Name or "Unknown Game"
end

function RefreshFriends()
    for _, child in pairs(FriendsLog:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local success, friends = pcall(function() return LocalPlayer:GetFriendsOnline(200) end)
    if success and friends then
        for _, friend in pairs(friends) do
            local fFrame = Instance.new("Frame", FriendsLog)
            fFrame.Size = UDim2.new(1, -5, 0, 60)
            fFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            fFrame.BackgroundTransparency = 0.0
            Instance.new("UICorner", fFrame).CornerRadius = UDim.new(0, 10)
            local fStroke = Instance.new("UIStroke", fFrame)
            fStroke.Color = Color3.fromRGB(219, 219, 219)
            fStroke.Thickness = 1

            local pfp = Instance.new("ImageButton", fFrame)
            pfp.Size = UDim2.new(0, 40, 0, 40)
            pfp.Position = UDim2.new(0, 8, 0.5, 0)
            pfp.AnchorPoint = Vector2.new(0, 0.5)
            pfp.BackgroundTransparency = 1
            pfp.AutoButtonColor = false
            Instance.new("UICorner", pfp).CornerRadius = UDim.new(1, 0)
            pfp.MouseButton1Click:Connect(function()
                showProfilePage(friend.VisitorId, friend.DisplayName, friend.UserName or friend.DisplayName)
            end)
            task.spawn(function()
                local content, ready = Players:GetUserThumbnailAsync(friend.VisitorId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                if ready then pfp.Image = content end
            end)

            local dot = Instance.new("Frame", fFrame)
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0, 38, 0.5, 8)
            dot.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

            local fName = Instance.new("TextLabel", fFrame)
            fName.Size = UDim2.new(1, -165, 0, 20)
            fName.Position = UDim2.new(0, 56, 0, 9)
            fName.Text = friend.DisplayName
            fName.TextColor3 = Color3.fromRGB(0, 0, 0)
            fName.Font = Enum.Font.GothamBold
            fName.TextSize = 13
            fName.TextXAlignment = Enum.TextXAlignment.Left
            fName.BackgroundTransparency = 1

            local fPresence = Instance.new("TextLabel", fFrame)
            fPresence.Size = UDim2.new(1, -165, 0, 16)
            fPresence.Position = UDim2.new(0, 56, 0, 30)
            fPresence.TextColor3 = Color3.fromRGB(100, 100, 100)
            fPresence.Font = Enum.Font.Gotham
            fPresence.TextSize = 11
            fPresence.TextXAlignment = Enum.TextXAlignment.Left
            fPresence.BackgroundTransparency = 1
            task.spawn(function()
                local gameName = GetPlaceName(friend.PlaceId)
                fPresence.Text = "[Game] " .. gameName
            end)

            local JoinBtn = Instance.new("TextButton", fFrame)
            JoinBtn.Size = UDim2.new(0, 48, 0, 24)
            JoinBtn.Position = UDim2.new(1, -54, 0.5, -12)
            JoinBtn.Text = "JOIN"
            JoinBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 80)
            JoinBtn.Font = Enum.Font.GothamBold
            JoinBtn.TextColor3 = Color3.new(1, 1, 1)
            JoinBtn.TextSize = 11
            Instance.new("UICorner", JoinBtn).CornerRadius = UDim.new(0, 6)

            local InviteBtn = Instance.new("TextButton", fFrame)
            InviteBtn.Size = UDim2.new(0, 52, 0, 24)
            InviteBtn.Position = UDim2.new(1, -110, 0.5, -12)
            InviteBtn.Text = "INVITE"
            InviteBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 200)
            InviteBtn.Font = Enum.Font.GothamBold
            InviteBtn.TextColor3 = Color3.new(1, 1, 1)
            InviteBtn.TextSize = 11
            Instance.new("UICorner", InviteBtn).CornerRadius = UDim.new(0, 6)

            JoinBtn.MouseButton1Click:Connect(function()
                TeleportService:TeleportToPlaceInstance(friend.PlaceId, friend.GameId, LocalPlayer)
            end)
            InviteBtn.MouseButton1Click:Connect(function()
                pcall(function() SocialService:PromptGameInvite(LocalPlayer) end)
            end)
        end
    end
end

local function SetActiveTab(page, btn)
    ChatPage.Visible = false
    FriendsPage.Visible = false
    LeaderboardPage.Visible = false
    MusicPage.Visible = false
    ScriptsPage.Visible = false
    Input.Parent.Visible = (page == ChatPage)
    ActivePageName = (page == FriendsPage and "Friends") or (page == LeaderboardPage and "Top") or (page == MusicPage and "YouTube") or (page == ScriptsPage and "Scripts") or "Chat"
    if page == ChatPage then
        if PrivateTargetId then
            Input.PlaceholderText = "[PVT] " .. tostring(PrivateTargetName or "User") .. "..."
        else
            Input.PlaceholderText = "* Type a message..."
            Input.Position = UDim2.new(0, 8, 0, 0)
            Input.Size = UDim2.new(1, -82, 1, 0)
            InputArea.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
        end
    end

    local allBtns = {ChatTabBtn, FriendsTabBtn, LeaderboardTabBtn, ScriptsTabBtn}
    if MusicTabBtn then table.insert(allBtns, MusicTabBtn) end
    for _, b in pairs(allBtns) do
        b.BackgroundTransparency = 0.0
        b.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
        b.TextColor3 = Color3.fromRGB(120, 120, 120)
    end

    page.Visible = true
    btn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
    btn.BackgroundTransparency = 0.0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

ChatTabBtn.MouseButton1Click:Connect(function() SetActiveTab(ChatPage, ChatTabBtn) end)
FriendsTabBtn.MouseButton1Click:Connect(function() SetActiveTab(FriendsPage, FriendsTabBtn) RefreshFriends() end)
LeaderboardTabBtn.MouseButton1Click:Connect(function() SetActiveTab(LeaderboardPage, LeaderboardTabBtn) RefreshLeaderboard() end)
ScriptsTabBtn.MouseButton1Click:Connect(function() SetActiveTab(ScriptsPage, ScriptsTabBtn) end)
if MusicTabBtn then
    MusicTabBtn.MouseButton1Click:Connect(function() SetActiveTab(MusicPage, MusicTabBtn) end)
end

ChatTabBtn.BackgroundTransparency = 0.0
ChatTabBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
ChatTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local function createNotification(sender, message, isPrivate, isSystem, senderUid, isAutoClean)
    if isAutoClean then return end
    if Main.Visible or activeNotification then return end

    local nFrame = Instance.new("Frame", NotifContainer)
    nFrame.Size = UDim2.new(1, 0, 0, 66)
    nFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    nFrame.BackgroundTransparency = 0.0
    nFrame.Position = UDim2.new(0, 0, -1.5, 0)
    Instance.new("UICorner", nFrame).CornerRadius = UDim.new(0, 12)
    local nStroke = Instance.new("UIStroke", nFrame)
    nStroke.Color = Color3.fromRGB(225, 48, 108)
    nStroke.Thickness = 1.2
    activeNotification = nFrame

    local pfpFrame = Instance.new("Frame", nFrame)
    pfpFrame.Size = UDim2.new(0, 42, 0, 42)
    pfpFrame.Position = UDim2.new(0, 12, 0.5, 0)
    pfpFrame.AnchorPoint = Vector2.new(0, 0.5)
    pfpFrame.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    pfpFrame.BorderSizePixel = 0
    Instance.new("UICorner", pfpFrame).CornerRadius = UDim.new(1, 0)

    if isSystem then
        local chickLabel = Instance.new("TextLabel", pfpFrame)
        chickLabel.Size = UDim2.new(1, 0, 1, 0)
        chickLabel.BackgroundTransparency = 1
        chickLabel.Text = "\240\159\144\165"
        chickLabel.Font = Enum.Font.GothamBold
        chickLabel.TextSize = 22
        chickLabel.TextXAlignment = Enum.TextXAlignment.Center
        chickLabel.TextYAlignment = Enum.TextYAlignment.Center
    else
        local pfp = Instance.new("ImageLabel", pfpFrame)
        pfp.Size = UDim2.new(1, 0, 1, 0)
        pfp.BackgroundTransparency = 1
        Instance.new("UICorner", pfp).CornerRadius = UDim.new(1, 0)
        if senderUid and senderUid ~= 0 then
            task.spawn(function()
                local content, isReady = Players:GetUserThumbnailAsync(senderUid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                if isReady then pfp.Image = content end
            end)
        end
    end

    local nText = Instance.new("TextLabel", nFrame)
    nText.Size = UDim2.new(1, -68, 1, -8)
    nText.Position = UDim2.new(0, 62, 0, 4)
    nText.BackgroundTransparency = 1
    nText.RichText = true

    local preview = SafeEncodeMsg(message)
    if #preview > 60 then preview = string.sub(preview, 1, 57) .. "..." end
    nText.Text = string.format(
        "<b><font color='rgb(0,0,0)'>%s</font></b>\n<font size='12' color='rgb(80,80,80)'>%s</font>",
        SafeEncodeMsg(sender), preview
    )
    nText.TextColor3 = Color3.fromRGB(0, 0, 0)
    nText.TextSize = 13
    nText.Font = Enum.Font.Gotham
    nText.TextXAlignment = Enum.TextXAlignment.Left
    nText.TextWrapped = false
    nText.TextTruncate = Enum.TextTruncate.AtEnd

    TweenService:Create(nFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 5)}):Play()
    task.delay(7, function()
        if nFrame and nFrame.Parent then
            local fadeOut = TweenService:Create(nFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, -1.5, 0), BackgroundTransparency = 1})
            fadeOut:Play()
            fadeOut.Completed:Connect(function() nFrame:Destroy() activeNotification = nil end)
        end
    end)
end

local function createBubble(player, text, isPrivate)

    if MutedPlayers[player.UserId] then return end
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return end
    local head = character.Head
    local existing = head:FindFirstChild("AresBubble")
    if existing then existing:Destroy() end
    local bGui = Instance.new("BillboardGui", head)
    bGui.Name = "AresBubble"
    bGui.Adornee = head
    bGui.Size = UDim2.new(0, math.clamp(#text * 14, 80, 320), 0, 54)
    bGui.StudsOffset = Vector3.new(0, 4, 0)
    bGui.MaxDistance = 80
    local bFrame = Instance.new("Frame", bGui)
    bFrame.Size = UDim2.new(1, 0, 1, 0)
    bFrame.BackgroundColor3 = isPrivate and Color3.fromRGB(255, 230, 245) or Color3.fromRGB(255, 255, 255)
    bFrame.BackgroundTransparency = 0.1
    Instance.new("UICorner", bFrame).CornerRadius = UDim.new(0, 14)
    local bStroke = Instance.new("UIStroke", bFrame)
    bStroke.Color = isPrivate and Color3.fromRGB(225, 48, 108) or Color3.fromRGB(200, 200, 200)
    bStroke.Thickness = 1.2
    local bText = Instance.new("TextLabel", bFrame)
    bText.Size = UDim2.new(1, -16, 1, -10)
    bText.Position = UDim2.new(0.5, 0, 0.5, 0)
    bText.AnchorPoint = Vector2.new(0.5, 0.5)
    bText.BackgroundTransparency = 1
    bText.Text = SafeEncodeMsg(text)
    bText.TextColor3 = Color3.fromRGB(0, 0, 0)
    bText.Font = Enum.Font.GothamMedium
    bText.TextSize = 16
    bText.TextWrapped = true
    task.delay(9, function() if bGui and bGui.Parent then bGui:Destroy() end end)
end

local function MakeDraggable(UI, DragTrigger)
    local Dragging, DragStart, StartPos
    DragTrigger.InputBegan:Connect(function(input)

        if isGuiLocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = UI.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isGuiLocked then Dragging = false return end
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = input.Position - DragStart
            UI.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)
end

MakeDraggable(Main, Header)

local toggleDragMoved = false
do
    local tbDragging, tbDragStart, tbStartPos
    ToggleBtn.InputBegan:Connect(function(input)

        if isGuiLocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            tbDragging  = true
            toggleDragMoved = false
            tbDragStart = input.Position
            tbStartPos  = ToggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    tbDragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isGuiLocked then tbDragging = false return end
        if tbDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
         or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - tbDragStart
            if delta.Magnitude > 5 then
                toggleDragMoved = true
                ToggleBtn.Position = UDim2.new(
                    tbStartPos.X.Scale, tbStartPos.X.Offset + delta.X,
                    tbStartPos.Y.Scale, tbStartPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

local function GetUserColor(name)
    local hash = 0
    for i = 1, #name do
        hash = (hash * 31 + string.byte(name, i)) % 360
    end

    local hue = ((hash * 7 + 40) % 360) / 360
    return Color3.fromHSV(hue, 0.72, 1.0)
end

local function applySystemBadgeImage(textButton, safeMsg)

    local cleanMsg = safeMsg:gsub("%s*%[ARES_BADGE:%d+%]%s*", "")
    return cleanMsg
end

local function trimMessages(messageKeys, buttonMap)
    messageKeys = messageKeys or sortedMessageKeys
    buttonMap = buttonMap or keyToButton
    local excess = #messageKeys - MAX_MESSAGES
    if excess <= 0 then return end

    local req = syn and syn.request or http and http.request or request

    for i = 1, excess do
        local oldestKey = messageKeys[1]
        if not oldestKey then break end

        table.remove(messageKeys, 1)
        local btn = buttonMap[oldestKey]
        buttonMap[oldestKey] = nil

        if btn and btn.Parent then
            TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
                TextTransparency = 1
            }):Play()
            task.delay(0.26, function()
                if btn and btn.Parent then
                    SpecialLabels[btn] = nil
                    NormalTitleLabels[btn] = nil
                    btn.Parent:Destroy()
                end
            end)
        end

        if req then
            local keyToDel = oldestKey
            task.spawn(function()
                pcall(function()
                    req({Url = DATABASE_URL .. "/" .. keyToDel .. ".json", Method = "DELETE"})
                end)
            end)
        end
    end
end

function addMessage(displayName, msg, isSystem, order, senderUid, isPrivate, skipBubble, replyTo, targetLog)

    if not isSystem and MutedPlayers[senderUid] then return end

    local safeName  = SafeEncodeMsg(tostring(displayName or ""))
    local safeMsg   = SafeEncodeMsg(tostring(msg or ""))
    local safeReply = replyTo and SafeEncodeMsg(tostring(replyTo)) or nil

    local myDisplayName = SafeEncodeMsg(RealDisplayName)
    local isReplyToMe = (not isSystem)
        and (safeReply ~= nil and safeReply ~= "")
        and string.find(string.lower(safeReply), string.lower(myDisplayName), 1, true) ~= nil
        and senderUid ~= RealUserId
    local isMyReply = (senderUid == RealUserId)
        and (safeReply ~= nil and safeReply ~= "")
        and (not isSystem)

    local renderLog = targetLog or ChatLog
    local activeMessageKeys = sortedMessageKeys
    local activeKeyToButton = keyToButton

    local rawMsg = tostring(msg or "")
    local stickerAssetId = string.match(rawMsg, "^%[STICKER:(%d+)%]$")

    local wrapperFrame = Instance.new("Frame", renderLog)
    wrapperFrame.Size = UDim2.new(1, 0, 0, 0)
    wrapperFrame.AutomaticSize = Enum.AutomaticSize.Y
    wrapperFrame.BackgroundTransparency = 1
    wrapperFrame.BorderSizePixel = 0

    wrapperFrame.LayoutOrder = (order and order ~= 0) and order or nextLocalOrder()
    wrapperFrame.ClipsDescendants = false

    local pfpOffset = 0
    if not isSystem and senderUid and senderUid ~= 0 then
        pfpOffset = 34
        local pfpImg = Instance.new("ImageButton", wrapperFrame)
        pfpImg.Size                   = UDim2.new(0, 26, 0, 26)
        pfpImg.Position               = UDim2.new(0, 2, 0, 5)
        pfpImg.AnchorPoint            = Vector2.new(0, 0)
        pfpImg.BackgroundColor3       = Color3.fromRGB(220, 220, 220)
        pfpImg.BackgroundTransparency = 0.0
        pfpImg.BorderSizePixel        = 0
        pfpImg.AutoButtonColor        = false
        pfpImg.ZIndex                 = 3
        Instance.new("UICorner", pfpImg).CornerRadius = UDim.new(1, 0)
        pfpImg.MouseButton1Click:Connect(function()
            showProfilePage(senderUid, safeName, safeName)
        end)
        task.spawn(function()
            local ok, content, ready = pcall(function()
                return Players:GetUserThumbnailAsync(
                    senderUid,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size48x48)
            end)
            if ok and ready then pfpImg.Image = content end
        end)
    end

    local TextButton = Instance.new("TextButton", wrapperFrame)
    TextButton.Size = UDim2.new(1, -pfpOffset, 0, 0)
    TextButton.AutomaticSize = Enum.AutomaticSize.Y
    TextButton.Position = UDim2.new(0, pfpOffset, 0, 0)
    TextButton.BackgroundTransparency = 0.0
    TextButton.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    TextButton.RichText = true
    TextButton.TextWrapped = true
    TextButton.Font = Enum.Font.Gotham
    TextButton.TextSize = 13
    TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    TextButton.TextXAlignment = Enum.TextXAlignment.Left
    TextButton.TextYAlignment = Enum.TextYAlignment.Top
    Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 6)

    local pad = Instance.new("UIPadding", TextButton)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 7)
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)

    if isMyReply then
        TextButton.BackgroundColor3 = Color3.fromRGB(220, 235, 255)
        TextButton.BackgroundTransparency = 0.0
    elseif isReplyToMe then
        TextButton.BackgroundColor3 = Color3.fromRGB(220, 248, 228)
        TextButton.BackgroundTransparency = 0.0
    end

    if safeReply and safeReply ~= "" and not stickerAssetId then

        local replyBoxH = 16
        pad.PaddingTop = UDim.new(0, replyBoxH + 4)

        local replyBox = Instance.new("Frame", TextButton)
        replyBox.Size = UDim2.new(1, -4, 0, replyBoxH)
        replyBox.AutomaticSize = Enum.AutomaticSize.None
        replyBox.Position = UDim2.new(0, -3, 0, -(replyBoxH + 2))
        replyBox.BackgroundColor3 = Color3.fromRGB(30, 20, 55)
        replyBox.BackgroundTransparency = 0.35
        replyBox.BorderSizePixel = 0
        replyBox.ZIndex = 2
        replyBox.ClipsDescendants = true
        Instance.new("UICorner", replyBox).CornerRadius = UDim.new(0, 4)

        local replyBoxStroke = Instance.new("UIStroke", replyBox)
        replyBoxStroke.Color = Color3.fromRGB(100, 80, 160)
        replyBoxStroke.Thickness = 0.8
        replyBoxStroke.Transparency = 0.5

        local replyBoxPad = Instance.new("UIPadding", replyBox)
        replyBoxPad.PaddingLeft   = UDim.new(0, 5)
        replyBoxPad.PaddingRight  = UDim.new(0, 5)
        replyBoxPad.PaddingTop    = UDim.new(0, 1)
        replyBoxPad.PaddingBottom = UDim.new(0, 1)

        local replyBoxLabel = Instance.new("TextLabel", replyBox)
        replyBoxLabel.Size = UDim2.new(1, 0, 1, 0)
        replyBoxLabel.AutomaticSize = Enum.AutomaticSize.None
        replyBoxLabel.BackgroundTransparency = 1
        replyBoxLabel.RichText = true
        local displayReply = safeReply:gsub("%[STICKER:%d+%]", "\240\159\142\173 Sticker")
        replyBoxLabel.Text = "\226\134\169 " .. displayReply
        replyBoxLabel.TextWrapped = false
        replyBoxLabel.TextTruncate = Enum.TextTruncate.AtEnd
        replyBoxLabel.Font = Enum.Font.Gotham
        replyBoxLabel.TextSize = 10
        replyBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
        replyBoxLabel.TextColor3 = Color3.fromRGB(160, 140, 200)
        replyBoxLabel.ZIndex = 3
    end

    if stickerAssetId and not isSystem then

        local tagData = TagCache[senderUid] or {text = "", type = "Normal"}
        if tagData.type == "Normal" then
            local ct = CustomTitles[senderUid]
            if ct then
                local now = os.time()
                if ct.expiresAt and ct.expiresAt > now then
                    tagData = { text = "[" .. ct.title .. "] ", type = "CustomTitle", tagTitle = "[" .. ct.title .. "]", titleColor = ct.color }
                end
            end
        end
        local privTag  = isPrivate and "<font color='rgb(255,100,255)'>[PVT] </font>" or ""
        local color    = GetUserColor(safeName)
        local colorStr = string.format("rgb(%d,%d,%d)",
            math.clamp(math.floor(color.R*255), 0, 255),
            math.clamp(math.floor(color.G*255), 0, 255),
            math.clamp(math.floor(color.B*255), 0, 255))

        local hasReplyInSticker = safeReply and safeReply ~= ""
        local replyBlockH       = hasReplyInSticker and 22 or 0
        local nameLabelY        = 5 + replyBlockH
        local sepY              = nameLabelY + 21
        local stickerImgY       = sepY + 3
        local stickerBubbleH    = stickerImgY + 76 + 5

        TextButton.AutomaticSize  = Enum.AutomaticSize.None
        TextButton.Size           = UDim2.new(1, 0, 0, stickerBubbleH)
        TextButton.BackgroundColor3       = Color3.fromRGB(245, 245, 245)
        TextButton.BackgroundTransparency = 0.0
        TextButton.Text           = ""
        pad.PaddingTop    = UDim.new(0, 0)
        pad.PaddingBottom = UDim.new(0, 0)
        pad.PaddingLeft   = UDim.new(0, 0)
        pad.PaddingRight  = UDim.new(0, 0)

        if hasReplyInSticker then
            local rBox = Instance.new("Frame", TextButton)
            rBox.Size                    = UDim2.new(1, -14, 0, 16)
            rBox.Position                = UDim2.new(0, 7, 0, 5)
            rBox.BackgroundColor3        = Color3.fromRGB(30, 20, 55)
            rBox.BackgroundTransparency  = 0.35
            rBox.BorderSizePixel         = 0
            rBox.ZIndex                  = TextButton.ZIndex + 1
            rBox.ClipsDescendants        = true
            Instance.new("UICorner", rBox).CornerRadius = UDim.new(0, 4)
            local rBoxStroke = Instance.new("UIStroke", rBox)
            rBoxStroke.Color       = Color3.fromRGB(100, 80, 160)
            rBoxStroke.Thickness   = 0.8
            rBoxStroke.Transparency = 0.5
            local rBoxPad = Instance.new("UIPadding", rBox)
            rBoxPad.PaddingLeft   = UDim.new(0, 5)
            rBoxPad.PaddingRight  = UDim.new(0, 5)
            rBoxPad.PaddingTop    = UDim.new(0, 1)
            rBoxPad.PaddingBottom = UDim.new(0, 1)
            local rBoxLabel = Instance.new("TextLabel", rBox)
            rBoxLabel.Size = UDim2.new(1, 0, 1, 0)
            rBoxLabel.AutomaticSize = Enum.AutomaticSize.None
            rBoxLabel.BackgroundTransparency = 1
            rBoxLabel.RichText = true
            local displayReplySt = safeReply:gsub("%[STICKER:%d+%]", "\240\159\142\173 Sticker")
            rBoxLabel.Text = "\226\134\169 " .. displayReplySt
            rBoxLabel.TextWrapped  = false
            rBoxLabel.TextTruncate = Enum.TextTruncate.AtEnd
            rBoxLabel.Font         = Enum.Font.Gotham
            rBoxLabel.TextSize     = 10
            rBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
            rBoxLabel.TextColor3   = Color3.fromRGB(160, 140, 200)
            rBoxLabel.ZIndex       = TextButton.ZIndex + 2
        end

        local nameLabel = Instance.new("TextLabel", TextButton)
        nameLabel.Size              = UDim2.new(1, -14, 0, 18)
        nameLabel.Position          = UDim2.new(0, 7, 0, nameLabelY)
        nameLabel.BackgroundTransparency = 1
        nameLabel.RichText          = true
        nameLabel.TextXAlignment    = Enum.TextXAlignment.Left
        nameLabel.Font              = Enum.Font.Gotham
        nameLabel.TextSize          = 12
        nameLabel.TextColor3        = Color3.new(1, 1, 1)
        nameLabel.ZIndex            = TextButton.ZIndex + 1
        nameLabel.TextTruncate      = Enum.TextTruncate.AtEnd

        if tagData.type ~= "Normal" then

            nameLabel.Text = string.format("%s%s<font color='%s'><b>%s</b></font>",
                privTag, tagData.text, colorStr, safeName)
            SpecialLabels[TextButton] = {
                displayName  = safeName,
                msg          = "",
                nameColor    = colorStr,
                isPrivate    = isPrivate,
                tagType      = tagData.type,
                tagTitle     = tagData.tagTitle,
                titleColor   = tagData.titleColor,
                replyTo      = nil,
                isSticker    = true,
                stickerLabel = nameLabel,
                senderUid    = senderUid,
            }
        else
            local _capStkBtn34  = TextButton
            local _capStkPvt34  = privTag
            local _capStkTag34  = tagData.text
            local _capStkClr34  = colorStr
            local _capStkNm34   = safeName
            local _capStkUid34  = senderUid
            local _capStkLbl34  = nameLabel
            nameLabel.Text = string.format("%s%s<font color='%s'><b>%s</b></font>",
                privTag, tagData.text, colorStr, safeName)

            if tagData.type == "Normal" then
                onBadgeLoaded(_capStkUid34, function()
                    if _capStkLbl34 and _capStkLbl34.Parent then
                        local fTitleType = getFollowerTitleType(_capStkUid34)
                        if fTitleType then

                            NormalTitleLabels[TextButton] = {
                                displayName = _capStkNm34,
                                msg         = safeMsg,
                                nameColor   = _capStkClr34,
                                isPrivate   = isPrivate,
                                senderUid   = _capStkUid34,
                                isSticker   = true,
                                stickerLabel = _capStkLbl34,
                            }
                        end
                    end
                end)
            end
        end

        local sep = Instance.new("Frame", TextButton)
        sep.Size                    = UDim2.new(1, -14, 0, 1)
        sep.Position                = UDim2.new(0, 7, 0, sepY)
        sep.BackgroundColor3        = Color3.fromRGB(100, 60, 180)
        sep.BackgroundTransparency  = 0.6
        sep.BorderSizePixel         = 0
        sep.ZIndex                  = TextButton.ZIndex + 1

        local stickerImg = Instance.new("ImageLabel", TextButton)
        stickerImg.Size              = UDim2.new(0, 76, 0, 76)
        stickerImg.Position          = UDim2.new(0, 7, 0, stickerImgY)
        stickerImg.BackgroundTransparency = 1
        stickerImg.Image             = "rbxthumb://type=Asset&id=" .. stickerAssetId .. "&w=150&h=150"
        stickerImg.ScaleType         = Enum.ScaleType.Fit
        stickerImg.ZIndex            = TextButton.ZIndex + 1

        local stickerBubbleStroke = Instance.new("UIStroke", TextButton)
        stickerBubbleStroke.Color       = Color3.fromRGB(219, 219, 219)
        stickerBubbleStroke.Thickness   = 1.2
        stickerBubbleStroke.Transparency = 0.0

        if not skipBubble then
            for _, p in pairs(Players:GetPlayers()) do
                if p.UserId == senderUid then createBubble(p, "\240\159\142\173 Sticker", isPrivate) end
            end
        end

    elseif isSystem then
        local systemMsgForDisplay = applySystemBadgeImage(TextButton, safeMsg)
        TextButton.Text = "<font color='rgb(200,100,0)'><b>[SYSTEM]</b></font> " .. systemMsgForDisplay
        TextButton.BackgroundColor3 = Color3.fromRGB(255, 248, 220)
    else
        local tagData = TagCache[senderUid] or {text = "", type = "Normal"}

        if tagData.type == "Normal" then
            local ct = CustomTitles[senderUid]
            if ct then
                local now = os.time()
                if ct.expiresAt and ct.expiresAt > now then
                    tagData = {
                        text       = "[" .. ct.title .. "] ",
                        type       = "CustomTitle",
                        tagTitle   = "[" .. ct.title .. "]",
                        titleColor = ct.color
                    }
                end
            end
        end
        local privTag = isPrivate and "<font color='rgb(255,100,255)'>[PVT] </font>" or ""
        local color = GetUserColor(safeName)
        local colorStr = string.format("rgb(%d,%d,%d)",
            math.clamp(math.floor(color.R*255), 0, 255),
            math.clamp(math.floor(color.G*255), 0, 255),
            math.clamp(math.floor(color.B*255), 0, 255))

        if tagData.type ~= "Normal" then
            SpecialLabels[TextButton] = {
                displayName = safeName,
                msg         = safeMsg,
                nameColor   = colorStr,
                isPrivate   = isPrivate,
                tagType     = tagData.type,
                tagTitle    = tagData.tagTitle,
                titleColor  = tagData.titleColor,
                replyTo     = safeReply,
                senderUid   = senderUid,
            }
            fetchBadgeAsync(senderUid)
        else
            local _capturedBtn34    = TextButton
            local _capturedPriv34   = privTag
            local _capturedTag34    = tagData.text
            local _capturedColor34  = colorStr
            local _capturedName34   = safeName
            local _capturedMsg34    = safeMsg
            local _capturedUid34    = senderUid

            _capturedBtn34.Text = string.format("%s%s<font color='%s'><b>%s</b></font>: %s",
                _capturedPriv34, _capturedTag34, _capturedColor34, _capturedName34, _capturedMsg34)
            onBadgeLoaded(_capturedUid34, function()
                if _capturedBtn34 and _capturedBtn34.Parent then
                    local fTitleType = getFollowerTitleType(_capturedUid34)
                    if fTitleType then

                        NormalTitleLabels[_capturedBtn34] = {
                            displayName = _capturedName34,
                            msg         = _capturedMsg34,
                            nameColor   = _capturedColor34,
                            isPrivate   = isPrivate,
                            senderUid   = _capturedUid34,
                        }
                    end
                end
            end)
        end

        if not skipBubble then
            for _, p in pairs(Players:GetPlayers()) do
                if p.UserId == senderUid then createBubble(p, safeMsg, isPrivate) end
            end
        end
    end

    if order and order ~= 0 then
        local keyStr = tostring(order)
        local inserted = false
        local numOrder = tonumber(keyStr) or 0
        for i = #activeMessageKeys, 1, -1 do
            local existingNum = tonumber(activeMessageKeys[i]) or 0
            if numOrder >= existingNum then
                table.insert(activeMessageKeys, i + 1, keyStr)
                inserted = true
                break
            end
        end
        if not inserted then
            table.insert(activeMessageKeys, 1, keyStr)
        end
        activeKeyToButton[keyStr] = TextButton
        task.spawn(function()
            trimMessages(activeMessageKeys, activeKeyToButton)
        end)

    end

    local holding = false
    local holdTriggered = false
    local swipeStartPos = nil
    local swipeTriggered = false
    local SWIPE_THRESHOLD = 25

    if not isSystem and senderUid ~= RealUserId then
        local nameHitboxY = (safeReply and safeReply ~= "") and 0 or 0
        local nameHitbox = Instance.new("Frame", TextButton)
        nameHitbox.Size = UDim2.new(0, 170, 0, 22)
        nameHitbox.Position = UDim2.new(0, 0, 0, nameHitboxY)
        nameHitbox.BackgroundTransparency = 1
        nameHitbox.BorderSizePixel = 0
        nameHitbox.ZIndex = 8
        nameHitbox.Active = true

        nameHitbox.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            holding = true
            holdTriggered = false
            task.delay(0.6, function()
                if holding and not swipeTriggered then
                    holdTriggered = true

                    PrivateTargetId = senderUid
                    PrivateTargetName = safeName
                    Input.PlaceholderText = "[PVT] " .. safeName .. "..."
                    InputArea.BackgroundColor3 = Color3.fromRGB(40, 10, 50)

                    PvtInputTag.Text = "[" .. safeName .. "]"
                    PvtInputTag.Visible = true
                    Input.Position = UDim2.new(0, 73, 0, 0)
                    Input.Size = UDim2.new(1, -117, 1, 0)
                end
            end)
        end)

        nameHitbox.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                local wasHolding = holding
                holding = false

                if not holdTriggered and not swipeTriggered and wasHolding then
                    task.spawn(function()
                        showProfilePage(senderUid, safeName, safeName)
                    end)
                end
            end
        end)
    end

    local swipeConn = nil
    local popupHoldFired = false

    local msgFbKey = (order and order ~= 0) and tostring(order) or nil
    local isOwnMsg = (senderUid == RealUserId)

    TextButton.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            swipeStartPos = inp.Position
            swipeTriggered = false
            popupHoldFired = false
            local tapPos = inp.Position

            task.delay(0.6, function()
                if swipeTriggered or popupHoldFired then return end
                if not (inp.UserInputState == Enum.UserInputState.Begin
                     or inp.UserInputState == Enum.UserInputState.Change) then return end

                if holdTriggered then return end
                popupHoldFired = true
                closeMsgPopup()

                local opts = {}

                table.insert(opts, {
                    icon = "\240\159\147\139", label = "Copy Text", destructive = false,
                    callback = function()
                        pcall(function()
                            if setclipboard then setclipboard(safeMsg)
                            elseif toclipboard then toclipboard(safeMsg) end
                        end)
                    end
                })

                if not isOwnMsg and not isSystem then

                    table.insert(opts, {
                        icon = "\240\159\145\164", label = "View Profile", destructive = false,
                        callback = function()
                            showProfilePage(senderUid, safeName, safeName)
                        end
                    })

                    table.insert(opts, {
                        icon = "\240\159\146\172", label = "PVT", destructive = false,
                        callback = function()
                            PrivateTargetId   = senderUid
                            PrivateTargetName = safeName
                            Input.PlaceholderText = "[PVT] " .. safeName .. "..."
                            InputArea.BackgroundColor3 = Color3.fromRGB(40, 10, 50)
                            PvtInputTag.Text    = "[" .. safeName .. "]"
                            PvtInputTag.Visible = true
                            Input.Position = UDim2.new(0, 73, 0, 0)
                            Input.Size     = UDim2.new(1, -117, 1, 0)
                        end
                    })

                    table.insert(opts, {
                        icon = "\226\134\169\239\184\143", label = "Reply", destructive = false,
                        callback = function()
                            ReplyTargetName = safeName
                            local replyDisplayMsg = safeMsg:match("^%[STICKER:%d+%]$") and "\240\159\142\173 Sticker" or safeMsg
                            ReplyTargetMsg  = replyDisplayMsg
                            ReplyBanner.Visible = true
                            ReplyLabel.Text = "Replying to " .. safeName .. ": " .. replyDisplayMsg
                            if isPrivate then
                                PrivateTargetId   = senderUid
                                PrivateTargetName = safeName
                                Input.PlaceholderText = "[PVT] " .. safeName .. "..."
                                InputArea.BackgroundColor3 = Color3.fromRGB(40, 10, 50)
                                PvtInputTag.Text    = "[" .. safeName .. "]"
                                PvtInputTag.Visible = true
                                Input.Position = UDim2.new(0, 73, 0, 0)
                                Input.Size     = UDim2.new(1, -117, 1, 0)
                            end
                        end
                    })
                end

                if isOwnMsg and not isSystem and msgFbKey then

                    table.insert(opts, {
                        icon = "\226\156\143\239\184\143", label = "Edit", destructive = false,
                        callback = function()
                            editingKey = msgFbKey

                            Input.Text = msg
                            Input.ClearTextOnFocus = false

                            InputArea.BackgroundColor3 = Color3.fromRGB(0, 40, 90)
                        end
                    })

                    table.insert(opts, {
                        icon = "\240\159\151\145\239\184\143", label = "Unsend", destructive = true,
                        callback = function()

                            local newKeys = {}
                            for _, k in ipairs(activeMessageKeys) do
                                if k ~= msgFbKey then table.insert(newKeys, k) end
                            end
                            for i = #activeMessageKeys, 1, -1 do
                                activeMessageKeys[i] = nil
                            end
                            for _, k in ipairs(newKeys) do
                                table.insert(activeMessageKeys, k)
                            end
                            activeKeyToButton[msgFbKey] = nil
                            SpecialLabels[TextButton] = nil

                            if wrapperFrame and wrapperFrame.Parent then
                                TweenService:Create(TextButton,
                                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                                    {BackgroundTransparency = 1}):Play()
                                task.delay(0.22, function()
                                    if wrapperFrame and wrapperFrame.Parent then
                                        wrapperFrame:Destroy()
                                    end
                                end)
                            end

                            local req = syn and syn.request or http and http.request or request
                            if req then
                                task.spawn(function()
                                    pcall(function()

                                        req({
                                            Url    = UNSENT_URL .. "/" .. msgFbKey .. ".json",
                                            Method = "PUT",
                                            Body   = HttpService:JSONEncode(true)
                                        })

                                        req({
                                            Url    = DATABASE_URL .. "/" .. msgFbKey .. ".json",
                                            Method = "DELETE"
                                        })

                                        task.delay(10, function()
                                            pcall(function()
                                                req({
                                                    Url    = UNSENT_URL .. "/" .. msgFbKey .. ".json",
                                                    Method = "DELETE"
                                                })
                                            end)
                                        end)
                                    end)
                                end)
                            end
                        end
                    })
                end

                showMsgPopup(Vector2.new(tapPos.X, tapPos.Y), opts)
            end)

            if swipeConn then swipeConn:Disconnect() swipeConn = nil end
            swipeConn = UserInputService.InputChanged:Connect(function(uiInp)
                if not swipeStartPos then return end
                if uiInp.UserInputType ~= Enum.UserInputType.MouseMovement
                and uiInp.UserInputType ~= Enum.UserInputType.Touch then return end
                if holdTriggered or swipeTriggered then return end
                local dx = uiInp.Position.X - swipeStartPos.X
                local dy = math.abs(uiInp.Position.Y - swipeStartPos.Y)
                local absDx = math.abs(dx)

                if absDx >= SWIPE_THRESHOLD and dy < 40 then
                    swipeTriggered = true
                    holding = false
                    if swipeConn then swipeConn:Disconnect() swipeConn = nil end

                    local slideOffset = (dx > 0) and 65 or -65
                    TweenService:Create(TextButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, pfpOffset + slideOffset, 0, 0)
                    }):Play()

                    local pfpImgRef = wrapperFrame:FindFirstChildWhichIsA("ImageButton") or wrapperFrame:FindFirstChildOfClass("ImageLabel")
                    if pfpImgRef then
                        TweenService:Create(pfpImgRef, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, 2 + slideOffset, 0, 5)
                        }):Play()
                    end
                    task.delay(0.15, function()
                        if TextButton and TextButton.Parent then
                            TweenService:Create(TextButton, TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                                Position = UDim2.new(0, pfpOffset, 0, 0)
                            }):Play()
                        end
                        if pfpImgRef and pfpImgRef.Parent then
                            TweenService:Create(pfpImgRef, TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                                Position = UDim2.new(0, 2, 0, 5)
                            }):Play()
                        end
                    end)

                    ReplyTargetName = safeName
                    local swipeReplyDisplayMsg = safeMsg:match("^%[STICKER:%d+%]$") and "\240\159\142\173 Sticker" or safeMsg
                    ReplyTargetMsg  = swipeReplyDisplayMsg
                    ReplyBanner.Visible = true
                    ReplyLabel.Text = "Replying to " .. safeName .. ": " .. swipeReplyDisplayMsg

                    if isPrivate and senderUid ~= RealUserId then
                        PrivateTargetId   = senderUid
                        PrivateTargetName = safeName
                        Input.PlaceholderText = "[PVT] " .. safeName .. "..."
                        InputArea.BackgroundColor3 = Color3.fromRGB(255, 230, 245)
                        PvtInputTag.Text    = "[" .. safeName .. "]"
                        PvtInputTag.Visible = true
                        Input.Position = UDim2.new(0, 73, 0, 0)
                        Input.Size     = UDim2.new(1, -117, 1, 0)
                    end
                end
            end)
        end
    end)

    TextButton.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            holding = false
            swipeStartPos = nil
            if swipeConn then swipeConn:Disconnect() swipeConn = nil end
        end
    end)

    task.spawn(function()
        for i = 1, 3 do
            RunService.Heartbeat:Wait()
        end
        if ChatLog and not _userScrolledUp then
            ChatLog.CanvasPosition = Vector2.new(0, 99999999)
        end
    end)
end

local function cleanDatabase()
    local req = syn and syn.request or http and http.request or request
    if req then req({Url = DATABASE_URL .. ".json", Method = "DELETE"}) end
end

local function broadcastCommand(targetId, cmdName, val)
    local timestamp = string.format("%012d", os.time()) .. math.random(100, 999)
    local data = {["Sender"] = "SYSTEM_CMD", ["TargetId"] = targetId, ["Cmd"] = cmdName, ["Val"] = val, ["Server"] = JobId}
    local req = syn and syn.request or http and http.request or request
    if req then
        req({Url = DATABASE_URL .. "/" .. timestamp .. ".json", Method = "PUT", Body = HttpService:JSONEncode(data)})
    end
end

local function handleLocalCommands(msg)
    local args = string.split(msg, " ")
    local cmd = string.lower(args[1])

    if cmd == "/clear" then
        for _, child in pairs(ChatLog:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        sortedMessageKeys = {}
        keyToButton = {}
        addMessage("SYSTEM", "Chat cleared locally.", true, 0, 0, false, true)
        return true

    elseif cmd == "/fly" then
        Flying = not Flying
        if Flying then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")

            local oldBV = hrp:FindFirstChild("AresFlyBV")
            local oldBG = hrp:FindFirstChild("AresFlyBG")
            if oldBV then oldBV:Destroy() end
            if oldBG then oldBG:Destroy() end
            if humanoid then humanoid.PlatformStand = true end
            local bv = Instance.new("BodyVelocity", hrp)
            bv.Name     = "AresFlyBV"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            local bg = Instance.new("BodyGyro", hrp)
            bg.Name      = "AresFlyBG"
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.P         = 2e5
            bg.D         = 1e3
            bg.CFrame    = hrp.CFrame
            task.spawn(function()
                while Flying and hrp and hrp.Parent do
                    RunService.Heartbeat:Wait()
                    local speed = 50
                    local cam   = workspace.CurrentCamera

                    local md = humanoid and humanoid.MoveDirection or Vector3.new(0,0,0)
                    local flatMove = Vector3.new(md.X, 0, md.Z)
                    local moveDir
                    if flatMove.Magnitude > 0.01 then
                        moveDir = flatMove.Unit * speed
                    else
                        moveDir = Vector3.new(0, 0, 0)
                    end

                    local goUp   = UserInputService:IsKeyDown(Enum.KeyCode.Space)
                                or UserInputService:IsKeyDown(Enum.KeyCode.E)
                    local goDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                                or UserInputService:IsKeyDown(Enum.KeyCode.Q)
                    if goUp   then moveDir = Vector3.new(moveDir.X,  speed, moveDir.Z) end
                    if goDown then moveDir = Vector3.new(moveDir.X, -speed, moveDir.Z) end
                    bv.Velocity = moveDir

                    local horizDir = Vector3.new(moveDir.X, 0, moveDir.Z)
                    if horizDir.Magnitude > 0.1 then
                        bg.CFrame = CFrame.lookAt(Vector3.new(0,0,0), horizDir)
                    else

                        local camFlat = Vector3.new(
                            cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                        if camFlat.Magnitude > 0.01 then
                            bg.CFrame = CFrame.lookAt(Vector3.new(0,0,0), camFlat)
                        end
                    end
                end

                if bv and bv.Parent then bv:Destroy() end
                if bg and bg.Parent then bg:Destroy() end
                if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
            end)
        else

            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bv = hrp:FindFirstChild("AresFlyBV")
                    local bg = hrp:FindFirstChild("AresFlyBG")
                    if bv then bv:Destroy() end
                    if bg then bg:Destroy() end
                end
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.PlatformStand = false end
            end
        end
        addMessage("SYSTEM", "Fly " .. (Flying and "enabled." or "disabled."), true, 0, 0, false, true)
        return true

    elseif cmd == "/noclip" then
        Noclip = not Noclip
        task.spawn(function()
            while Noclip do
                RunService.Stepped:Wait()
                if LocalPlayer.Character then
                    for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end)
        addMessage("SYSTEM", "Noclip " .. (Noclip and "enabled." or "disabled."), true, 0, 0, false, true)
        return true

    elseif cmd == "/nosit" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Sit = false
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        end
        addMessage("SYSTEM", "Sit disabled.", true, 0, 0, false, true)
        return true

    elseif cmd == "/sit" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Sit = true
        end
        addMessage("SYSTEM", "Sitting.", true, 0, 0, false, true)
        return true

    elseif cmd == "/speed" and args[2] and not args[3] then
        local val = tonumber(args[2])
        if val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = val
            addMessage("SYSTEM", "WalkSpeed set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/jump" and args[2] and not args[3] then
        local val = tonumber(args[2])
        if val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = val
            addMessage("SYSTEM", "JumpPower set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/invisible" and not args[2] then
        IsInvisible = not IsInvisible
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = IsInvisible and 1 or 0
                end
            end
        end
        addMessage("SYSTEM", "Invisibility " .. (IsInvisible and "enabled." or "disabled."), true, 0, 0, false, true)
        return true

    elseif cmd == "/me" then
        local rest = table.concat(args, " ", 2)
        if rest ~= "" then
            return false
        end
        return true

    elseif cmd == "/time" then
        local h = tonumber(os.date("%H"))
        local m = os.date("%M")
        local ampm = h >= 12 and "PM" or "AM"
        h = h % 12
        if h == 0 then h = 12 end
        addMessage("SYSTEM", "Current time: " .. h .. ":" .. m .. " " .. ampm, true, 0, 0, false, true)
        return true

    elseif cmd == "/name" and args[2] then
        local newName = table.concat(args, " ", 2)
        if game.PlaceId == 4924922222 then
            local rs = game:GetService("ReplicatedStorage")
            local rpRemote = rs:FindFirstChild("RE")
            if rpRemote then
                local nameRemote = rpRemote:FindFirstChild("1RPNam1eTex1t")
                if nameRemote then
                    pcall(function() nameRemote:FireServer("RolePlayName", newName) end)
                    addMessage("SYSTEM", "RP name set to: " .. newName, true, 0, 0, false, true)
                end
            end
        else
            addMessage("SYSTEM", "Name command only works in Brookhaven.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/mute" and args[2] then
        local targetName = table.concat(args, " ", 2)
        local target = GetPlayerByName(targetName)
        if target then
            if target.UserId == RealUserId then
                addMessage("SYSTEM", "You cannot mute yourself.", true, 0, 0, false, true)
            elseif CREATOR_IDS[target.UserId] then
                addMessage("SYSTEM", "You cannot mute the Creator.", true, 0, 0, false, true)
            else
                MutedPlayers[target.UserId] = true
                addMessage("SYSTEM", "Locally muted " .. target.DisplayName .. ". Only you see this.", true, 0, 0, false, true)
            end
        else
            addMessage("SYSTEM", "Player '" .. targetName .. "' not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/unmute" and args[2] then
        local targetName = table.concat(args, " ", 2)
        local target = GetPlayerByName(targetName)
        if target then
            MutedPlayers[target.UserId] = nil
            addMessage("SYSTEM", "Locally unmuted " .. target.DisplayName .. ".", true, 0, 0, false, true)
        else
            addMessage("SYSTEM", "Player '" .. targetName .. "' not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/view" and args[2] then
        local target = GetPlayerByName(args[2])
        if target and target.Character then
            workspace.CurrentCamera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid") or target.Character:FindFirstChild("HumanoidRootPart")
            addMessage("SYSTEM", "Viewing " .. target.DisplayName .. ".", true, 0, 0, false, true)
        else
            addMessage("SYSTEM", "Player not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/unview" then
        if LocalPlayer.Character then
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            addMessage("SYSTEM", "Camera restored.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/to" and args[2] then
        local target = GetPlayerByName(args[2])
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(4, 0, 0)
                addMessage("SYSTEM", "Teleported to " .. target.DisplayName .. ".", true, 0, 0, false, true)
            end
        else
            addMessage("SYSTEM", "Player not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/goto" and args[2] then
        local target = GetPlayerByName(args[2])
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(4, 0, 0)
                addMessage("SYSTEM", "Teleported to " .. target.DisplayName .. ".", true, 0, 0, false, true)
            end
        else
            addMessage("SYSTEM", "Player not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/bring" and args[2] then
        local target = GetPlayerByName(args[2])
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                target.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(4, 0, 0)
                addMessage("SYSTEM", "Brought " .. target.DisplayName .. " to you (local).", true, 0, 0, false, true)
            end
        else
            addMessage("SYSTEM", "Player not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/ws" and args[2] then
        local val = tonumber(args[2])
        if val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = val
            addMessage("SYSTEM", "WalkSpeed set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/jp" and args[2] then
        local val = tonumber(args[2])
        if val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = val
            addMessage("SYSTEM", "JumpPower set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/gravity" and args[2] then
        local val = tonumber(args[2])
        if val then
            workspace.Gravity = val
            addMessage("SYSTEM", "Gravity set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/fog" and args[2] then
        local val = tonumber(args[2])
        if val then
            local lighting = game:GetService("Lighting")
            lighting.FogEnd = val
            addMessage("SYSTEM", "Fog end set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/day" then
        game:GetService("Lighting").ClockTime = 14
        addMessage("SYSTEM", "Time set to day.", true, 0, 0, false, true)
        return true

    elseif cmd == "/night" then
        game:GetService("Lighting").ClockTime = 0
        addMessage("SYSTEM", "Time set to night.", true, 0, 0, false, true)
        return true

    elseif cmd == "/reset" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
            addMessage("SYSTEM", "Resetting character...", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/respawn" then
        LocalPlayer:LoadCharacter()
        addMessage("SYSTEM", "Respawning...", true, 0, 0, false, true)
        return true

    elseif cmd == "/heal" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hum = LocalPlayer.Character.Humanoid
            hum.Health = hum.MaxHealth
            addMessage("SYSTEM", "Health restored.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/god" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.MaxHealth = math.huge
            LocalPlayer.Character.Humanoid.Health    = math.huge
            addMessage("SYSTEM", "God mode ON.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/ungod" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.MaxHealth = 100
            LocalPlayer.Character.Humanoid.Health    = 100
            addMessage("SYSTEM", "God mode OFF.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/ping" then
        local stats = game:GetService("Stats")
        local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        addMessage("SYSTEM", "Ping: " .. math.floor(ping) .. " ms", true, 0, 0, false, true)
        return true

    elseif cmd == "/players" then
        addMessage("SYSTEM", "Players in server:", true, 0, 0, false, true)
        for _, p in pairs(Players:GetPlayers()) do
            addMessage("SYSTEM", "  \226\128\162 " .. p.DisplayName .. " (@" .. p.Name .. ")", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/server" then
        addMessage("SYSTEM", "Server ID: " .. tostring(JobId), true, 0, 0, false, true)
        return true

    elseif cmd == "/gameid" then
        addMessage("SYSTEM", "Game ID: " .. tostring(game.GameId), true, 0, 0, false, true)
        return true

    elseif cmd == "/placeid" then
        addMessage("SYSTEM", "Place ID: " .. tostring(game.PlaceId), true, 0, 0, false, true)
        return true

    elseif cmd == "/fps" then
        local fps = math.floor(1/RunService.Heartbeat:Wait())
        addMessage("SYSTEM", "FPS: ~" .. fps, true, 0, 0, false, true)
        return true

    elseif cmd == "/zoom" and args[2] then
        local val = tonumber(args[2])
        if val then
            LocalPlayer.CameraMaxZoomDistance = val
            LocalPlayer.CameraMinZoomDistance = math.min(val, LocalPlayer.CameraMinZoomDistance)
            addMessage("SYSTEM", "Camera zoom set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/fov" and args[2] then
        local val = tonumber(args[2])
        if val then
            workspace.CurrentCamera.FieldOfView = val
            addMessage("SYSTEM", "FOV set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/spin" then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local old = hrp:FindFirstChild("AresSpinBG")
            if old then old:Destroy() end
            local bg = Instance.new("BodyAngularVelocity", hrp)
            bg.Name = "AresSpinBG"
            bg.AngularVelocity = Vector3.new(0, 20, 0)
            bg.MaxTorque = Vector3.new(0, 1e9, 0)
            bg.P = 1e5
            addMessage("SYSTEM", "Spinning! /unspin to stop.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/unspin" then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local bg = char.HumanoidRootPart:FindFirstChild("AresSpinBG")
            if bg then bg:Destroy() end
            addMessage("SYSTEM", "Spin stopped.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/lock" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = true
            addMessage("SYSTEM", "Self locked (frozen).", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/unlock" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
            addMessage("SYSTEM", "Self unlocked.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/hitbox" and args[2] then
        local val = tonumber(args[2])
        if val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Size = Vector3.new(val, val, val)
            addMessage("SYSTEM", "Hitbox size set to " .. val .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/tools" then
        pcall(function()
            local sp = game:GetService("StarterPack")
            local bp = LocalPlayer.Backpack
            for _, tool in pairs(sp:GetChildren()) do
                if tool:IsA("Tool") and not bp:FindFirstChild(tool.Name) then
                    tool:Clone().Parent = bp
                end
            end
        end)
        addMessage("SYSTEM", "Tools added from StarterPack.", true, 0, 0, false, true)
        return true

    elseif cmd == "/notools" then
        if LocalPlayer.Backpack then
            for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do t:Destroy() end
        end
        if LocalPlayer.Character then
            for _, t in pairs(LocalPlayer.Character:GetChildren()) do if t:IsA("Tool") then t:Destroy() end end
        end
        addMessage("SYSTEM", "All tools removed.", true, 0, 0, false, true)
        return true

    elseif cmd == "/shout" and args[2] then
        local text = table.concat(args, " ", 2)
        return false

    elseif cmd == "/afk" then
        addMessage("SYSTEM", "AFK mode toggled. Others will see your AFK tag.", true, 0, 0, false, true)
        return true

    elseif cmd == "/info" and args[2] then
        local target = GetPlayerByName(args[2])
        if target then
            addMessage("SYSTEM", "=== Info: " .. target.DisplayName .. " ===", true, 0, 0, false, true)
            addMessage("SYSTEM", "Username: @" .. target.Name, true, 0, 0, false, true)
            addMessage("SYSTEM", "UserID: " .. tostring(target.UserId), true, 0, 0, false, true)
            addMessage("SYSTEM", "Account Age: " .. tostring(target.AccountAge) .. " days", true, 0, 0, false, true)
            addMessage("SYSTEM", "Team: " .. (target.Team and target.Team.Name or "None"), true, 0, 0, false, true)
        else
            addMessage("SYSTEM", "Player not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/age" and args[2] then
        local target = GetPlayerByName(args[2])
        if target then
            addMessage("SYSTEM", target.DisplayName .. " account age: " .. tostring(target.AccountAge) .. " days", true, 0, 0, false, true)
        else
            addMessage("SYSTEM", "Player not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/online" then
        local count = #Players:GetPlayers()
        addMessage("SYSTEM", "Players online: " .. count .. "/" .. Players.MaxPlayers, true, 0, 0, false, true)
        return true

    elseif cmd == "/dms" then
        addMessage("SYSTEM", "Hold a message and tap PVT to start a private chat.", true, 0, 0, false, true)
        return true

    elseif cmd == "/ambient" and args[2] and args[3] and args[4] then
        local r, g, b = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
        if r and g and b then
            game:GetService("Lighting").Ambient = Color3.fromRGB(r, g, b)
            addMessage("SYSTEM", "Ambient set to " .. r .. "," .. g .. "," .. b .. ".", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/dance" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            pcall(function()
                local animTrack = hum:LoadAnimation(Instance.new("Animation"))
                animTrack:Play()
            end)
        end
        addMessage("SYSTEM", "Dance command sent! (Game must support animations)", true, 0, 0, false, true)
        return true

    elseif cmd == "/sit2" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Sit = true
            addMessage("SYSTEM", "Force sitting.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/lag" then
        local stats = game:GetService("Stats")
        local ping = 0
        pcall(function() ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        addMessage("SYSTEM", "Network ping: ~" .. math.floor(ping) .. "ms", true, 0, 0, false, true)
        return true

    elseif cmd == "/back" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
            addMessage("SYSTEM", "Teleported to origin.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/pm" and args[2] and args[3] then
        local target = GetPlayerByName(args[2])
        if target then
            PrivateTargetId   = target.UserId
            PrivateTargetName = target.DisplayName
            Input.PlaceholderText = "[PVT] " .. target.DisplayName .. "..."
            InputArea.BackgroundColor3 = Color3.fromRGB(40, 10, 50)
            PvtInputTag.Text    = "[" .. target.DisplayName .. "]"
            PvtInputTag.Visible = true
            Input.Position = UDim2.new(0, 73, 0, 0)
            Input.Size     = UDim2.new(1, -117, 1, 0)
            addMessage("SYSTEM", "PM mode to " .. target.DisplayName .. " activated.", true, 0, 0, false, true)
        else
            addMessage("SYSTEM", "Player not found.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/emote" and args[2] then
        local emoteName = args[2]
        addMessage("SYSTEM", "Emote '" .. emoteName .. "' \226\128\148 use /e " .. emoteName .. " in Roblox chat for in-game emotes.", true, 0, 0, false, true)
        return true

    elseif cmd == "/nametag" and args[2] then
        local tagText = table.concat(args, " ", 2)
        if LocalPlayer.Character then
            for _, d in pairs(LocalPlayer.Character:GetDescendants()) do
                if d:IsA("BillboardGui") and d.Name == "AresNameTag" then d:Destroy() end
            end
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")
            if hrp then
                local bb = Instance.new("BillboardGui", hrp)
                bb.Name = "AresNameTag"
                bb.Size = UDim2.new(0, 100, 0, 26)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = false
                local lbl = Instance.new("TextLabel", bb)
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text = tagText
                lbl.TextColor3 = Color3.fromRGB(220, 180, 255)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 14
                addMessage("SYSTEM", "Nametag set to: " .. tagText, true, 0, 0, false, true)
            end
        end
        return true

    elseif cmd == "/hat" then
        if LocalPlayer.Character then
            for _, acc in pairs(LocalPlayer.Character:GetChildren()) do
                if acc:IsA("Accessory") then
                    local h = acc:FindFirstChild("Handle")
                    if h then h.Transparency = 0 end
                end
            end
            addMessage("SYSTEM", "Accessories shown.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/nohat" then
        if LocalPlayer.Character then
            for _, acc in pairs(LocalPlayer.Character:GetChildren()) do
                if acc:IsA("Accessory") then
                    local h = acc:FindFirstChild("Handle")
                    if h then h.Transparency = 1 end
                end
            end
            addMessage("SYSTEM", "Accessories hidden.", true, 0, 0, false, true)
        end
        return true

    elseif cmd == "/commands" then
        local commandList = {
            "=== MOVEMENT ===",
            "/fly \226\128\148 Toggle fly",
            "/noclip \226\128\148 Toggle noclip",
            "/sit \226\128\148 Force sit",
            "/sit2 \226\128\148 Force sit (script-side)",
            "/nosit \226\128\148 Disable sit",
            "/spin \226\128\148 Start spinning",
            "/unspin \226\128\148 Stop spinning",
            "/lock \226\128\148 Freeze self (anchored)",
            "/unlock \226\128\148 Unfreeze self",
            "/dance \226\128\148 Play dance emote",
            "",
            "=== TELEPORT ===",
            "/to [name] \226\128\148 Teleport to player",
            "/goto [name] \226\128\148 Teleport to player (alias)",
            "/bring [name] \226\128\148 Bring player to you (local)",
            "/back \226\128\148 Teleport to origin (0,0,0)",
            "",
            "=== STATS ===",
            "/speed [val] \226\128\148 Set WalkSpeed",
            "/ws [val] \226\128\148 Set WalkSpeed (alias)",
            "/jump [val] \226\128\148 Set JumpPower",
            "/jp [val] \226\128\148 Set JumpPower (alias)",
            "/gravity [val] \226\128\148 Set gravity",
            "/zoom [val] \226\128\148 Set camera zoom",
            "/fov [val] \226\128\148 Set field of view",
            "",
            "=== HEALTH ===",
            "/heal \226\128\148 Restore max health",
            "/god \226\128\148 God mode (infinite health)",
            "/ungod \226\128\148 Disable god mode",
            "",
            "=== WORLD ===",
            "/fog [val] \226\128\148 Set fog end distance",
            "/day \226\128\148 Set daytime",
            "/night \226\128\148 Set nighttime",
            "/ambient [r] [g] [b] \226\128\148 Set ambient color",
            "",
            "=== CAMERA ===",
            "/view [name] \226\128\148 Spectate a player",
            "/unview \226\128\148 Restore camera",
            "",
            "=== PLAYER INFO ===",
            "/players \226\128\148 List all players",
            "/info [name] \226\128\148 Player info",
            "/age [name] \226\128\148 Account age",
            "/online \226\128\148 Players online count",
            "/ping \226\128\148 Show ping",
            "/fps \226\128\148 Show FPS",
            "/lag \226\128\148 Network stats",
            "/server \226\128\148 Server ID",
            "/gameid \226\128\148 Game ID",
            "/placeid \226\128\148 Place ID",
            "",
            "=== APPEARANCE ===",
            "/invisible \226\128\148 Toggle own invisibility",
            "/hat \226\128\148 Show accessories",
            "/nohat \226\128\148 Hide accessories",
            "/nametag [text] \226\128\148 Set local nametag",
            "/hitbox [val] \226\128\148 Resize HRP hitbox",
            "",
            "=== TOOLS ===",
            "/tools \226\128\148 Get StarterPack tools",
            "/notools \226\128\148 Remove all tools",
            "",
            "=== CHAT ===",
            "/me [text] \226\128\148 Roleplay action message",
            "/pm [name] [msg] \226\128\148 Private message",
            "/dms \226\128\148 Private chat reminder",
            "/afk \226\128\148 AFK reminder",
            "/emote [name] \226\128\148 Emote hint",
            "",
            "=== MISC ===",
            "/time \226\128\148 Show current time",
            "/name [text] \226\128\148 RP name (Brookhaven)",
            "/mute [name] \226\128\148 Locally mute player",
            "/unmute [name] \226\128\148 Locally unmute player",
            "/clear \226\128\148 Clear local chat",
            "/reset \226\128\148 Reset character",
            "/respawn \226\128\148 Reload character",
            "/commands \226\128\148 Show this list",
        }
        addMessage("SYSTEM", "\226\149\148\226\149\144\226\149\144 ARES RECHAT COMMANDS \226\149\144\226\149\144\226\149\151", true, 0, 0, false, true)
        for _, line in ipairs(commandList) do
            addMessage("SYSTEM", line, true, 0, 0, false, true)
        end
        addMessage("SYSTEM", "\226\149\154\226\149\144\226\149\144 END OF COMMANDS \226\149\144\226\149\144\226\149\157", true, 0, 0, false, true)
        return true

    end

    return false
end

send = function(msg, isSystem, isAutoClean)
    if msg == "" then return end

    if isKickedOrBanned then return end

    if editingKey and not isSystem then
        local ekCopy  = editingKey
        editingKey    = nil
        Input.ClearTextOnFocus = true
        InputArea.BackgroundColor3 = Color3.fromRGB(20, 10, 45)

        local btn = keyToButton[ekCopy]
        if btn then
            local safeNewMsg = SafeEncodeMsg(msg)
            if SpecialLabels[btn] then

                SpecialLabels[btn].msg = safeNewMsg
            elseif NormalTitleLabels[btn] then

                NormalTitleLabels[btn].msg = safeNewMsg
            else

                local cur = btn.Text or ""
                local colonPos = string.find(cur, ": ", 1, true)
                if colonPos then
                    btn.Text = string.sub(cur, 1, colonPos + 1) .. safeNewMsg
                end
            end
        end

        task.spawn(function()
            pcall(function()
                local req2 = syn and syn.request or http and http.request or request
                if req2 then
                    req2({
                        Url    = DATABASE_URL .. "/" .. ekCopy .. ".json",
                        Method = "PATCH",
                        Body   = HttpService:JSONEncode({Content = msg})
                    })
                end
            end)
        end)
        return
    end

    if #msg > MAX_CHAR_LIMIT then
        addMessage("SYSTEM", "Message too long! Max " .. MAX_CHAR_LIMIT .. " characters.", true, 0, 0, false, true)
        return
    end

    if not isSystem and string.sub(msg, 1, 1) ~= "/" then
        local now = os.time()

        if now - _spamWindowStart >= SPAM_WINDOW then
            _spamCount = 0
            _spamWindowStart = now
        end

        if now - _lastSentTime < SPAM_INTERVAL then
            addMessage("SYSTEM", "\226\155\148 Slow down! You are sending messages too fast.", true, 0, 0, false, true)
            return
        end

        if msg == _lastSentMsg then
            addMessage("SYSTEM", "\226\155\148 Don't repeat the same message.", true, 0, 0, false, true)
            return
        end

        _spamCount = _spamCount + 1
        if _spamCount > SPAM_MAX then
            addMessage("SYSTEM", "\226\155\148 Anti-spam: You've sent too many messages. Please wait.", true, 0, 0, false, true)
            _spamCount = SPAM_MAX
            return
        end
        _lastSentTime = now
        _lastSentMsg  = msg
    end

    local args = string.split(msg, " ")
    if string.lower(args[1]) == "/me" then
        local rest = table.concat(args, " ", 2)
        if rest ~= "" then
            local emoteMsg = "* " .. RealDisplayName .. " " .. rest .. " *"
            local timestamp = string.format("%012d", os.time()) .. math.random(100, 999)
            local data = {
                ["Sender"]      = "SYSTEM",
                ["SenderUid"]   = RealUserId,
                ["Content"]     = emoteMsg,
                ["Server"]      = JobId,
                ["IsSystem"]    = true,
                ["IsAutoClean"] = false,
                ["TargetId"]    = nil,
                ["ReplyTo"]     = nil
            }
            processedKeys[timestamp] = true
            addMessage("SYSTEM", emoteMsg, true, tonumber(timestamp) or 0, 0, false, false, nil)
            task.spawn(function()
                local req = syn and syn.request or http and http.request or request
                if req then req({Url = DATABASE_URL .. "/" .. timestamp .. ".json", Method = "PUT", Body = HttpService:JSONEncode(data)}) end
            end)
            lastMessageTime = os.time()
        end
        return
    end

    if handleLocalCommands(msg) then return end

    if CREATOR_IDS[RealUserId] and string.sub(msg, 1, 1) == "/" then
        local cmd = string.lower(args[1])
        local targetName = args[2] or ""
        local target = GetPlayerByName(targetName)

        if cmd == "/kick" and target then
            broadcastCommand(target.UserId, "kick", "Kicked by Ares Creator.")
            return

        elseif cmd == "/ban" and target then
            task.spawn(function()
                local req = syn and syn.request or http and http.request or request
                if req then
                    pcall(function()
                        req({
                            Url    = BAN_URL .. "/" .. tostring(target.UserId) .. ".json",
                            Method = "PUT",
                            Body   = HttpService:JSONEncode({
                                name        = target.Name,
                                displayName = target.DisplayName,
                                bannedAt    = os.time()
                            })
                        })
                    end)
                end
            end)
            broadcastCommand(target.UserId, "ban", "You are permanently banned from Ares Chat.")
            return

        elseif cmd == "/unban" and args[2] then
            local unbanTarget = GetPlayerByName(args[2])
            local unbanId = nil
            if unbanTarget then
                unbanId = unbanTarget.UserId
            else

                unbanId = tonumber(args[2])
            end
            if unbanId then
                task.spawn(function()
                    local req = syn and syn.request or http and http.request or request
                    if req then
                        pcall(function()
                            req({
                                Url    = BAN_URL .. "/" .. tostring(unbanId) .. ".json",
                                Method = "DELETE"
                            })
                        end)
                    end
                end)
                addMessage("SYSTEM", "Unbanned user ID " .. tostring(unbanId) .. ".", true, 0, 0, false, true)
            else
                addMessage("SYSTEM", "Player or ID not found for /unban.", true, 0, 0, false, true)
            end
            return

        elseif cmd == "/title" and target and args[3] and args[4] then
            local colourArg = string.lower(args[3])
            local titleColourRGB
            if colourArg == "red" then
                titleColourRGB = "rgb(220,50,50)"
            elseif colourArg == "white" then
                titleColourRGB = "rgb(240,240,240)"
            elseif colourArg == "yellow" then
                titleColourRGB = "rgb(255,200,0)"
            elseif colourArg == "black" then
                titleColourRGB = "rgb(40,40,40)"
            else
                addMessage("SYSTEM", "Invalid colour. Use: red, white, yellow, black. Usage: /title [name] [colour] [text]", true, 0, 0, false, true)
                return
            end
            local titleText = table.concat(args, " ", 4)
            local expiresAt = os.time() + 86400
            CustomTitles[target.UserId] = {title = titleText, expiresAt = expiresAt, color = titleColourRGB}

            TagCache[target.UserId] = nil

            task.spawn(function()
                local req = syn and syn.request or http and http.request or request
                if req then
                    pcall(function()
                        req({
                            Url    = CUSTOM_TITLES_URL .. "/" .. tostring(target.UserId) .. ".json",
                            Method = "PUT",
                            Body   = HttpService:JSONEncode({
                                title       = titleText,
                                expiresAt   = expiresAt,
                                color       = titleColourRGB,
                                name        = target.Name,
                                displayName = target.DisplayName
                            })
                        })
                    end)
                end
            end)
            addMessage("SYSTEM", "Gave [" .. titleText .. "] title (" .. colourArg .. ") to " .. target.DisplayName .. " for 1 day.", true, 0, 0, false, true)
            return

        elseif cmd == "/untitle" and target then
            CustomTitles[target.UserId] = nil

            TagCache[target.UserId] = nil

            task.spawn(function()
                local req = syn and syn.request or http and http.request or request
                if req then
                    pcall(function()
                        req({
                            Url    = CUSTOM_TITLES_URL .. "/" .. tostring(target.UserId) .. ".json",
                            Method = "DELETE"
                        })
                    end)
                end
            end)
            addMessage("SYSTEM", "Removed custom title from " .. target.DisplayName .. ".", true, 0, 0, false, true)
            return

        elseif cmd == "/kill" and target then broadcastCommand(target.UserId, "kill", "") return
        elseif cmd == "/re" and target then broadcastCommand(target.UserId, "re", "") return
        elseif cmd == "/freeze" and target then broadcastCommand(target.UserId, "freeze", true) return
        elseif cmd == "/unfreeze" and target then broadcastCommand(target.UserId, "freeze", false) return
        elseif cmd == "/make" and args[2] and target then broadcastCommand(target.UserId, "make", args[2]) return
        elseif cmd == "/clear" then cleanDatabase() processedKeys = {} sortedMessageKeys = {} keyToButton = {} return

        elseif cmd == "/speed" and target and args[3] then
            broadcastCommand(target.UserId, "speed", tonumber(args[3])) return

        elseif cmd == "/jump" and target and args[3] then
            broadcastCommand(target.UserId, "jumppower", tonumber(args[3])) return

        elseif cmd == "/tp2me" and target then
            broadcastCommand(target.UserId, "tp2me", RealUserId) return

        elseif cmd == "/invisible" and target then
            broadcastCommand(target.UserId, "invisible", "") return

        elseif cmd == "/mute" and target then
            broadcastCommand(target.UserId, "mute", true) return

        elseif cmd == "/unmute" and target then
            broadcastCommand(target.UserId, "mute", false) return

        elseif cmd == "/announce" then
            local announcement = table.concat(args, " ", 2)
            if announcement ~= "" then
                local ts = string.format("%012d", os.time()) .. math.random(100, 999)
                local pkt = {
                    ["Sender"]      = "SYSTEM",
                    ["SenderUid"]   = 0,
                    ["Content"]     = "\240\159\147\162 ANNOUNCEMENT: " .. announcement,
                    ["Server"]      = "GLOBAL",
                    ["IsSystem"]    = true,
                    ["IsAutoClean"] = false
                }
                local req = syn and syn.request or http and http.request or request
                if req then req({Url = DATABASE_URL .. "/" .. ts .. ".json", Method = "PUT", Body = HttpService:JSONEncode(pkt)}) end
            end
            return
        end
    end

    if (RealUserId == OWNER_ID or GRANDFATHER_IDS[RealUserId]) and string.sub(msg, 1, 1) == "/" then
        local cmd = string.lower(args[1])
        local targetName = args[2] or ""
        local target = GetPlayerByName(targetName)

        if cmd == "/kick" and target then broadcastCommand(target.UserId, "kick", "Kicked by Ares Owner.") return
        elseif cmd == "/kill" and target then broadcastCommand(target.UserId, "kill", "") return
        elseif cmd == "/re" and target then broadcastCommand(target.UserId, "re", "") return
        elseif cmd == "/freeze" and target then broadcastCommand(target.UserId, "freeze", true) return
        elseif cmd == "/unfreeze" and target then broadcastCommand(target.UserId, "freeze", false) return
        elseif cmd == "/make" and args[2] and target then broadcastCommand(target.UserId, "make", args[2]) return
        elseif cmd == "/clear" then cleanDatabase() processedKeys = {} sortedMessageKeys = {} keyToButton = {} return

        elseif cmd == "/speed" and target and args[3] then
            broadcastCommand(target.UserId, "speed", tonumber(args[3])) return

        elseif cmd == "/jump" and target and args[3] then
            broadcastCommand(target.UserId, "jumppower", tonumber(args[3])) return

        elseif cmd == "/tp2me" and target then
            broadcastCommand(target.UserId, "tp2me", RealUserId) return

        elseif cmd == "/invisible" and target then
            broadcastCommand(target.UserId, "invisible", "") return

        elseif cmd == "/mute" and target then
            broadcastCommand(target.UserId, "mute", true) return

        elseif cmd == "/unmute" and target then
            broadcastCommand(target.UserId, "mute", false) return

        elseif cmd == "/announce" then
            local announcement = table.concat(args, " ", 2)
            if announcement ~= "" then
                local ts = string.format("%012d", os.time()) .. math.random(100, 999)
                local pkt = {
                    ["Sender"]      = "SYSTEM",
                    ["SenderUid"]   = 0,
                    ["Content"]     = "\240\159\147\162 ANNOUNCEMENT: " .. announcement,
                    ["Server"]      = "GLOBAL",
                    ["IsSystem"]    = true,
                    ["IsAutoClean"] = false
                }
                local req = syn and syn.request or http and http.request or request
                if req then req({Url = DATABASE_URL .. "/" .. ts .. ".json", Method = "PUT", Body = HttpService:JSONEncode(pkt)}) end
            end
            return
        end
    end

    local effectiveTargetId = PrivateTargetId
    local effectivePrivateName = PrivateTargetName

    local timestamp = string.format("%012d", os.time()) .. math.random(100, 999)
    local replyStr = ReplyTargetName and (ReplyTargetName .. ": " .. (ReplyTargetMsg or "")) or nil
    local data = {
        ["Sender"]      = RealDisplayName,
        ["SenderUid"]   = RealUserId,
        ["Content"]     = msg,
        ["Server"]      = JobId,
        ["IsSystem"]    = isSystem or false,
        ["IsAutoClean"] = isAutoClean or false,
        ["TargetId"]    = effectiveTargetId,
        ["ReplyTo"]     = replyStr
    }
    processedKeys[timestamp] = true
    addMessage(RealDisplayName, msg, isSystem, tonumber(timestamp) or 0, RealUserId, effectiveTargetId ~= nil, false, replyStr)

    ReplyTargetName = nil
    ReplyTargetMsg  = nil
    ReplyBanner.Visible = false
    ReplyLabel.Text = "Replying to ..."

    lastMessageTime = os.time()

    task.spawn(function()
        local req = syn and syn.request or http and http.request or request
        if req then req({Url = DATABASE_URL .. "/" .. timestamp .. ".json", Method = "PUT", Body = HttpService:JSONEncode(data)}) end
    end)
end

local lastData = ""
local function sync()
    local req = syn and syn.request or http and http.request or request
    if not req then return end
    pcall(function()

        local res = req({Url = DATABASE_URL .. ".json?orderBy=\"$key\"&limitToLast=25", Method = "GET"})
        if res.Success and res.Body ~= "null" and res.Body ~= lastData then
            lastData = res.Body
            local data = HttpService:JSONDecode(res.Body)
            if data then
                local keys = {}
                for k in pairs(data) do table.insert(keys, k) end
                table.sort(keys)
                for _, k in ipairs(keys) do
                    local msgData = data[k]
                    if not processedKeys[k] then
                        if msgData.Sender == "SYSTEM_CMD" and msgData.TargetId == RealUserId then
                            if msgData.Cmd == "kick" or msgData.Cmd == "ban" then

                                isKickedOrBanned = true
                                LocalPlayer:Kick(msgData.Val)
                            elseif msgData.Cmd == "kill" then
                                if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
                            elseif msgData.Cmd == "re" then
                                LocalPlayer:LoadCharacter()
                            elseif msgData.Cmd == "freeze" then
                                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    LocalPlayer.Character.HumanoidRootPart.Anchored = msgData.Val
                                end
                            elseif msgData.Cmd == "speed" then
                                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                                    LocalPlayer.Character.Humanoid.WalkSpeed = msgData.Val
                                end
                            elseif msgData.Cmd == "jumppower" then
                                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                                    LocalPlayer.Character.Humanoid.JumpPower = msgData.Val
                                end
                            elseif msgData.Cmd == "make" then
                                TagCache[RealUserId] = {text = "[" .. string.upper(msgData.Val) .. "] ", type = "Normal"}
                            elseif msgData.Cmd == "tp2me" then

                                local ownerId = tonumber(msgData.Val)
                                if ownerId then
                                    local ownerPlayer = nil
                                    for _, p in pairs(Players:GetPlayers()) do
                                        if p.UserId == ownerId then ownerPlayer = p break end
                                    end
                                    if ownerPlayer and ownerPlayer.Character and ownerPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                            LocalPlayer.Character.HumanoidRootPart.CFrame = ownerPlayer.Character.HumanoidRootPart.CFrame
                                        end
                                    end
                                end
                            elseif msgData.Cmd == "invisible" then
                                if LocalPlayer.Character then
                                    IsInvisible = not IsInvisible
                                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                                        if part:IsA("BasePart") or part:IsA("Decal") then
                                            part.Transparency = IsInvisible and 1 or 0
                                        end
                                    end
                                end
                            elseif msgData.Cmd == "mute" then

                                MutedPlayers[msgData.TargetId] = (msgData.Val == true)
                            end
                        end

                        if msgData.Sender == "SYSTEM_CMD" and msgData.Cmd == "mute" then
                            MutedPlayers[msgData.TargetId] = (msgData.Val == true)
                        end

                        if (msgData.Server == JobId or msgData.Server == "GLOBAL") and msgData.Sender ~= "SYSTEM_CMD" and not msgData.IsDeleted and not msgData.IsDM then
                            local isPrivate = msgData.TargetId ~= nil
                            local canSee = not isPrivate or (msgData.TargetId == RealUserId or msgData.SenderUid == RealUserId)
                            if canSee then

                                local senderMuted = (not msgData.IsSystem) and MutedPlayers[msgData.SenderUid]
                                if not senderMuted then
                                    local isAutoClean = msgData.IsAutoClean or false
                                    addMessage(msgData.Sender, msgData.Content, msgData.IsSystem, tonumber(k) or 0, msgData.SenderUid, isPrivate, false, msgData.ReplyTo)

                                    if msgData.SenderUid ~= RealUserId then

                                        local notifContent = msgData.Content or ""

                                        if string.match(notifContent, "^%[STICKER:%d+%]$") then
                                            notifContent = "\240\159\142\173 Sent a sticker"
                                        elseif #notifContent > 80 then
                                            notifContent = string.sub(notifContent, 1, 80)
                                        end
                                        createNotification(msgData.Sender, notifContent, isPrivate, msgData.IsSystem, msgData.SenderUid, isAutoClean)
                                    end

                                    lastMessageTime = os.time()
                                end
                            end
                        end
                        processedKeys[k] = true
                    elseif msgData then

                        if msgData.IsDeleted and keyToButton[k] then
                            local btn = keyToButton[k]
                            local wf  = btn and btn.Parent
                            keyToButton[k] = nil
                            if btn then SpecialLabels[btn] = nil end
                            if btn then NormalTitleLabels[btn] = nil end
                            local newKeys = {}
                            for _, sk in ipairs(sortedMessageKeys) do
                                if sk ~= k then table.insert(newKeys, sk) end
                            end
                            sortedMessageKeys = newKeys
                            if wf and wf.Parent then wf:Destroy() end
                        end

                        if not msgData.IsDeleted and keyToButton[k] and msgData.Content then
                            local btn = keyToButton[k]
                            local safeEditMsg = SafeEncodeMsg(msgData.Content)
                            if SpecialLabels[btn] then
                                SpecialLabels[btn].msg = safeEditMsg
                            elseif NormalTitleLabels[btn] then
                                NormalTitleLabels[btn].msg = safeEditMsg
                            else
                                local cur = btn and btn.Text or ""
                                local colonPos = string.find(cur, ": ", 1, true)
                                if colonPos then
                                    local newText = string.sub(cur, 1, colonPos+1) .. safeEditMsg
                                    if newText ~= cur then
                                        btn.Text = newText
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function syncOnline()
    local req = syn and syn.request or http and http.request or request
    if not req then return end
    pcall(function()
        local res = req({Url = ONLINE_URL .. "/" .. JobId .. ".json", Method = "GET"})
        if res.Success and res.Body ~= "null" then
            local onlineData = HttpService:JSONDecode(res.Body)
            if type(onlineData) == "table" then
                for uid, _ in pairs(onlineData) do
                    scriptUsersInServer[tonumber(uid)] = true
                end
            end
        end
    end)
end

local function syncCustomTitles()
    local req = syn and syn.request or http and http.request or request
    if not req then return end
    pcall(function()
        local res = req({Url = CUSTOM_TITLES_URL .. ".json", Method = "GET"})
        if res and res.Success and res.Body ~= "null" then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok and type(data) == "table" then
                local now = os.time()
                local changed = false
                for uidStr, entry in pairs(data) do
                    local uid = tonumber(uidStr)
                    if uid and type(entry) == "table" then
                        if entry.expiresAt and entry.expiresAt > now then
                            local existing = CustomTitles[uid]
                            if not existing or existing.title ~= entry.title or existing.expiresAt ~= entry.expiresAt then
                                CustomTitles[uid] = {title = entry.title, expiresAt = entry.expiresAt, color = entry.color}
                                TagCache[uid] = nil
                                changed = true
                            end
                        else

                            if CustomTitles[uid] then
                                CustomTitles[uid] = nil
                                TagCache[uid] = nil
                                changed = true
                            end
                        end
                    end
                end

                for uid, _ in pairs(CustomTitles) do
                    if not data[tostring(uid)] then
                        CustomTitles[uid] = nil
                        TagCache[uid] = nil
                        changed = true
                    end
                end
            end
        elseif res and res.Success and res.Body == "null" then

            for uid, _ in pairs(CustomTitles) do
                CustomTitles[uid] = nil
                TagCache[uid] = nil
            end
        end
    end)
end

task.spawn(function()
    task.wait(5)
    while true do
        pcall(function()
            local req = syn and syn.request or http and http.request or request
            if req then
                local res = req({Url = BAN_URL .. "/" .. tostring(RealUserId) .. ".json", Method = "GET"})
                if res and res.Success and res.Body ~= "null" and res.Body ~= "" and res.Body ~= "false" then
                    isKickedOrBanned = true

                end
            end
        end)
        task.wait(60)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()

    if toggleDragMoved then
        toggleDragMoved = false
        return
    end
    Main.Visible = not Main.Visible
    ToggleBtn.Text = Main.Visible and "X" or "*"
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    ToggleBtn.Text = "*"
end)

Input.FocusLost:Connect(function(enter)
    if enter then
        local txt = Input.Text
        Input.Text = ""
        send(txt, false, false)
    end
end)

SendBtn.MouseButton1Click:Connect(function()
    local txt = Input.Text
    Input.Text = ""
    send(txt, false, false)
end)

task.spawn(function()
    local req = syn and syn.request or http and http.request or request
    if req then
        local uid = tostring(RealUserId)
        pcall(function()
            req({
                Url = ONLINE_URL .. "/" .. JobId .. "/" .. uid .. ".json",
                Method = "PUT",
                Body = HttpService:JSONEncode(RealDisplayName)
            })
        end)
        scriptUsersInServer[RealUserId] = true
    end
end)

task.spawn(function()
    task.wait(1)
    syncOnline()
end)

task.spawn(function()
    task.wait(1.5)
    for _, child in pairs(ChatLog:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    sortedMessageKeys = {}
    keyToButton = {}

end)

local function showUpdateOverlay()
    local updateOverlay = Instance.new("Frame", ScreenGui)
    updateOverlay.Size = Main.Size
    updateOverlay.Position = Main.Position
    updateOverlay.AnchorPoint = Main.AnchorPoint
    updateOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    updateOverlay.BackgroundTransparency = 0.0
    updateOverlay.BorderSizePixel = 0
    updateOverlay.ZIndex = 800
    updateOverlay.ClipsDescendants = true
    Instance.new("UICorner", updateOverlay).CornerRadius = UDim.new(0, 16)
    local updateStroke = Instance.new("UIStroke", updateOverlay)
    updateStroke.Color = Color3.fromRGB(225, 48, 108)
    updateStroke.Thickness = 1.6

    local title = Instance.new("TextLabel", updateOverlay)
    title.Size = UDim2.new(1, -28, 0, 34)
    title.Position = UDim2.new(0, 14, 0, 14)
    title.BackgroundTransparency = 1
    title.Text = "Ares ReChat V53 Update"
    title.TextColor3 = Color3.fromRGB(225, 48, 108)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 801

    local body = Instance.new("TextLabel", updateOverlay)
    body.Size = UDim2.new(1, -28, 1, -110)
    body.Position = UDim2.new(0, 14, 0, 54)
    body.BackgroundTransparency = 1
    body.Text = "Latest update:\n\226\128\162 10 FOLLOWER = Premium Title.\n\226\128\162 50 FOLLOWERS = Legend Title.\n\226\128\162 100 FOLLOWERS = VIP Title.\n\226\128\162 New light and dark theme button side of lock button.\n\nUsage:\n\226\128\162 Swipe a message to reply.\n\226\128\162 Hold a message for actions.\n\226\128\162 Use /commands to view all commands.\n\nContact:\n\226\128\162 Insta = greatest.ares\n\226\128\162 Discord = the_ares_offical"
    body.TextColor3 = Color3.fromRGB(40, 40, 40)
    body.Font = Enum.Font.GothamBold
    body.TextSize = 15
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.ZIndex = 801

    local continueBtn = Instance.new("TextButton", updateOverlay)
    continueBtn.Size = UDim2.new(1, -28, 0, 36)
    continueBtn.Position = UDim2.new(0, 14, 1, -50)
    continueBtn.BackgroundColor3 = Color3.fromRGB(225, 48, 108)
    continueBtn.BackgroundTransparency = 0.0
    continueBtn.BorderSizePixel = 0
    continueBtn.Text = "Continue"
    continueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    continueBtn.Font = Enum.Font.GothamBold
    continueBtn.TextSize = 14
    continueBtn.ZIndex = 801
    Instance.new("UICorner", continueBtn).CornerRadius = UDim.new(0, 9)
    continueBtn.MouseButton1Click:Connect(function()
        TweenService:Create(updateOverlay, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
        task.delay(0.18, function()
            if updateOverlay and updateOverlay.Parent then updateOverlay:Destroy() end
        end)
    end)
end

task.spawn(function()
    showUpdateOverlay()
end)

task.spawn(function()

    local myTitle = ""
    pcall(function()
        local req = syn and syn.request or http and http.request or request
        if req then
            local res = req({ Url = FOLLOWERS_URL .. "/" .. tostring(RealUserId) .. ".json", Method = "GET" })
            if res and res.Success and res.Body ~= "null" then
                local ok, fdata = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok and type(fdata) == "table" then
                    local count = 0
                    for _ in pairs(fdata) do count = count + 1 end
                    badgeCache[RealUserId] = count
                    followerCountCache[RealUserId] = count

                    local hasHardcoded = (CREATOR_IDS[RealUserId] or RealUserId == OWNER_ID
                        or CUTE_IDS[RealUserId] or HELLGOD_IDS[RealUserId]
                        or VIP_IDS[RealUserId] or GRANDFATHER_IDS[RealUserId]
                        or DADDY_IDS[RealUserId])
                    if not hasHardcoded then
                        myTitle = getFollowerTitleFromCount(count)
                    end
                end
            end
        end
    end)

    local joinMsg = RealDisplayName .. myTitle .. " joined the chat!"
    if CREATOR_IDS[RealUserId] then
        joinMsg = "\226\154\161 [\225\180\132\202\128\225\180\135\225\180\128\225\180\155\225\180\143\202\128] \226\154\161 THE ALMIGHTY CREATOR " .. RealDisplayName:upper() .. " HAS DESCENDED UPON THIS REALM! THE ARCHITECT OF ARES IS PRESENT! ALL SHALL WITNESS! \226\154\161"
    elseif RealUserId == OWNER_ID then
        joinMsg = "\240\159\145\145 [\226\151\142\225\186\152\206\183\226\132\174\210\145] THE SUPREME OWNER HAS ARRIVED! ALL HAIL " .. RealDisplayName:upper() .. "! BOW DOWN BEFORE THE \226\151\142\225\186\152\206\183\226\132\174\210\145! \240\159\145\145"
    elseif CUTE_IDS[RealUserId] then
        joinMsg = "[CUTE] THE CUTEST PERSON " .. RealDisplayName:upper() .. " HAS JOINED!"
    elseif HELLGOD_IDS[RealUserId] then
        joinMsg = "\240\159\148\165 [HellGod] THE HELLGOD " .. RealDisplayName:upper() .. " HAS RISEN FROM THE DEPTHS! TREMBLE BEFORE THEM! \240\159\148\165"
    elseif DADDY_IDS[RealUserId] then
        joinMsg = "\240\159\146\156 [DADDY] " .. RealDisplayName:upper() .. " HAS JOINED THE CHAT!"
    elseif GRANDFATHER_IDS[RealUserId] then
        joinMsg = "(\225\180\128\225\180\133\225\180\141\201\170\201\180)  \234\156\177\225\180\128\225\180\155\225\180\155\202\143 \202\156\225\180\128\234\156\177 \225\180\138\225\180\156\234\156\177\225\180\155 \225\180\128\202\128\202\128\201\170\225\180\160\225\180\135\225\180\133\240\159\152\190\n\226\128\156Not everyone has to understand the vibe; it was never made for everyone.\226\128\157\240\159\152\139"
    elseif VIP_IDS[RealUserId] then
        joinMsg = "[VIP] THE VIP " .. RealDisplayName:upper() .. " HAS JOINED!"
    end

    local joinTimestamp = string.format("%012d", os.time()) .. math.random(100, 999)
    local joinPacket = {
        ["Sender"]      = "SYSTEM",
        ["SenderUid"]   = 0,
        ["Content"]     = joinMsg,
        ["Server"]      = JobId,
        ["IsSystem"]    = true,
        ["IsAutoClean"] = false
    }
    local req = syn and syn.request or http and http.request or request
    if req then
        local sent = false
        for attempt = 1, 3 do
            local ok = pcall(function()
                local res = req({Url = DATABASE_URL .. "/" .. joinTimestamp .. ".json", Method = "PUT", Body = HttpService:JSONEncode(joinPacket)})
                if not res or not (res.Success or (type(res.StatusCode) == "number" and res.StatusCode >= 200 and res.StatusCode < 300)) then
                    error("join broadcast failed, status = " .. tostring(res and res.StatusCode))
                end
            end)
            if ok then
                sent = true
                break
            end
            task.wait(1)
        end
        if not sent then
            warn("[ARES] join notification failed after 3 attempts")
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player ~= LocalPlayer then return end
    scriptUsersInServer[player.UserId] = nil
    task.spawn(function()
        local req = syn and syn.request or http and http.request or request
        if req then
            pcall(function()
                req({
                    Url = ONLINE_URL .. "/" .. JobId .. "/" .. tostring(player.UserId) .. ".json",
                    Method = "DELETE"
                })
            end)
        end
    end)

end)

local MUSIC_SC_CLIENT_ID = "Pb72ranhoyt6gw7hM7TkzUItXlMWSNSo"
local musicClientIdRefreshing  = false
local musicLastClientIdRefresh = 0
local musicCurrentResults = {}
local musicCurrentIndex   = 0
local musicCurrentTrack   = nil
local musicIsPlaying      = false
local musicIsPaused       = false
local musicIsBusy         = false
local musicTrackToken     = 0
local musicProgressConn   = nil
local musicEndedConn      = nil
local musicShuffleOn      = false
local musicLoopOn         = false
local musicAudioPlayer    = nil
local musicLastBroadcastUrl = ""
local musicVolLevels      = { 1, 0.75, 0.5, 0.25 }
local musicVolIdx         = 1
local musicIsSeeking      = false
local musicCurrentQuery   = ""
local musicCurrentOffset  = 0

local function getMusicAudioPlayer()
    if not musicAudioPlayer or not musicAudioPlayer.Parent then
        musicAudioPlayer = Instance.new("Sound")
        musicAudioPlayer.Parent = game:GetService("SoundService")
        musicAudioPlayer.Volume = 1
        musicAudioPlayer.Name   = "AresMusicPlayer"
    end
    return musicAudioPlayer
end

local function musicFormatTime(secs)
    secs = math.floor(tonumber(secs) or 0)
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end














local function musicLog(msg)
    warn("[ARES MUSIC] " .. tostring(msg))
end

local MUSIC_ID_PATTERNS = {
    'client_id[:=]"(%w+)"',      
    "client_id[:=]'(%w+)'",      
    'client_id=(%w+)&',          
    '"client_id":"(%w+)"',       
}

local function musicExtractIdFromBody(body)
    if not body then return nil end
    for _, pat in ipairs(MUSIC_ID_PATTERNS) do
        for foundId in string.gmatch(body, pat) do
            if type(foundId) == "string" and #foundId >= 16 and #foundId <= 40 then
                return foundId
            end
        end
    end
    return nil
end

local function musicFetchFreshClientId()
    local req = syn and syn.request or http and http.request or request
    if not req then
        musicLog("no HTTP request function available on this executor")
        return nil
    end
    local scHeaders = {
        ["User-Agent"]      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        ["Referer"]         = "https://soundcloud.com/",
        ["Accept"]          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.9",
    }

    local homeOk, homeRes = pcall(function()
        return req({ Url = "https://soundcloud.com", Method = "GET", Headers = scHeaders })
    end)
    if not homeOk then
        musicLog("home page request threw: " .. tostring(homeRes))
        return nil
    end
    if not homeRes then
        musicLog("home page request returned nothing")
        return nil
    end
    local homeStatusOk = homeRes.Success or (type(homeRes.StatusCode) == "number" and homeRes.StatusCode >= 200 and homeRes.StatusCode < 300)
    if not homeStatusOk then
        musicLog("home page fetch failed, status = " .. tostring(homeRes.StatusCode))
        return nil
    end
    if not homeRes.Body or #homeRes.Body == 0 then
        musicLog("home page body was empty")
        return nil
    end

    
    
    local scriptUrls = {}
    for tag in string.gmatch(homeRes.Body, "<script[^>]->") do
        local u = string.match(tag, 'src="([^"]+)"')
        if u and (string.find(u, "assets", 1, true) or string.find(u, "a%-v2", 1) or string.find(u, "sndcdn", 1, true)) then
            table.insert(scriptUrls, u)
        end
    end
    if #scriptUrls == 0 then
        musicLog("home page returned no matching <script> bundles (likely blocked/challenged) \226\128\148 got " .. #homeRes.Body .. " bytes")
        return nil
    end

    
    
    local resultId  = nil
    local remaining = #scriptUrls
    local doneEvent = false

    for _, scriptUrl in ipairs(scriptUrls) do
        task.spawn(function()
            local jsOk, jsRes = pcall(function()
                return req({ Url = scriptUrl, Method = "GET", Headers = scHeaders })
            end)
            if jsOk and jsRes then
                local jsStatusOk = jsRes.Success or (type(jsRes.StatusCode) == "number" and jsRes.StatusCode >= 200 and jsRes.StatusCode < 300)
                if jsStatusOk and jsRes.Body then
                    local foundId = musicExtractIdFromBody(jsRes.Body)
                    if foundId and not resultId then
                        resultId = foundId
                    end
                end
            end
            remaining = remaining - 1
        end)
    end

    local waited = 0
    while not resultId and remaining > 0 and waited < 12 do
        task.wait(0.1)
        waited = waited + 0.1
    end

    if not resultId then
        musicLog("scanned " .. #scriptUrls .. " bundle(s), no client_id token matched any known pattern")
    end
    return resultId
end



local function musicRefreshClientId(force)
    if musicClientIdRefreshing then
        local waited = 0
        while musicClientIdRefreshing and waited < 12 do
            task.wait(0.25)
            waited = waited + 0.25
        end
        return MUSIC_SC_CLIENT_ID
    end
    if not force and (os.time() - musicLastClientIdRefresh) < 10 then
        return MUSIC_SC_CLIENT_ID
    end
    musicClientIdRefreshing = true
    local ok, newId = pcall(musicFetchFreshClientId)
    if ok and newId and newId ~= MUSIC_SC_CLIENT_ID then
        musicLog("refreshed client_id: " .. MUSIC_SC_CLIENT_ID .. " -> " .. newId)
        MUSIC_SC_CLIENT_ID = newId
    elseif not ok then
        musicLog("scraper errored: " .. tostring(newId))
    end
    musicLastClientIdRefresh = os.time()
    musicClientIdRefreshing = false
    return MUSIC_SC_CLIENT_ID
end






getgenv().AresForceRefreshSCId = function()
    return musicRefreshClientId(true)
end
getgenv().AresSetSCClientId = function(id)
    if type(id) == "string" and #id >= 16 then
        MUSIC_SC_CLIENT_ID = id
        musicLog("client_id manually set to " .. id)
        return true
    end
    return false
end

local function musicSafeGet(url, _isRetry)
    if not url or url == "" then return nil end
    local req = syn and syn.request or http and http.request or request
    if not req then return nil end
    local ok, res = pcall(function() return req({ Url = url, Method = "GET" }) end)
    local statusOk = ok and res and (res.Success or (type(res.StatusCode) == "number" and res.StatusCode >= 200 and res.StatusCode < 300))
    if statusOk and res.Body and #res.Body > 0 then
        return res.Body
    end

    if not ok then
        musicLog("request threw: " .. tostring(res))
    elseif res then
        musicLog("request failed, status = " .. tostring(res.StatusCode))
    end

    
    
    if not _isRetry and string.find(url, "client_id=", 1, true) and string.find(url, MUSIC_SC_CLIENT_ID, 1, true) then
        local oldId = MUSIC_SC_CLIENT_ID
        local freshId = musicRefreshClientId(true)
        if freshId and freshId ~= oldId then
            local newUrl = string.gsub(url, oldId, freshId)
            return musicSafeGet(newUrl, true)
        else
            musicLog("client_id refresh did not produce a new id \226\128\148 search/playback will keep failing until soundcloud.com is scrape-able again, or call AresSetSCClientId(\"...\") manually")
        end
    end

    return nil
end


local function musicDownloadFile(url, path)
    local body = musicSafeGet(url)
    if not body then return nil end
    local ok = pcall(writefile, path, body)
    if not ok then return nil end
    task.wait(0.08)
    local asset
    pcall(function() asset = getcustomasset(path) end)
    return asset
end

local function musicStopProgressLoop()
    if musicProgressConn then
        pcall(function() musicProgressConn:Disconnect() end)
        musicProgressConn = nil
    end
end

local function musicStartProgressLoop()
    musicStopProgressLoop()
    local ap = getMusicAudioPlayer()
    local accum = 0
    musicProgressConn = RunService.Heartbeat:Connect(function(dt)
        accum = accum + dt
        if accum < 0.1 then return end
        accum = 0
        if musicIsSeeking then return end
        if not ap or not ap.IsPlaying then return end
        local len = ap.TimeLength
        local pos = ap.TimePosition
        if len and len > 0 then
            local ratio = math.clamp(pos / len, 0, 1)
            if MusicProgressFill and MusicProgressFill.Parent then
                MusicProgressFill.Size = UDim2.new(ratio, 0, 1, 0)
            end
            if MusicSeekKnob and MusicSeekKnob.Parent then
                MusicSeekKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
            end
            if MusicTimeLeft and MusicTimeLeft.Parent then
                MusicTimeLeft.Text = musicFormatTime(pos)
            end
            if MusicTimeRight and MusicTimeRight.Parent then
                MusicTimeRight.Text = musicFormatTime(len)
            end
        end
    end)
end

local function musicSetProgressVisible(v)
    if MusicProgressBG  and MusicProgressBG.Parent  then MusicProgressBG.Visible  = v end
    if MusicTimeLeft    and MusicTimeLeft.Parent    then MusicTimeLeft.Visible     = v end
    if MusicTimeRight   and MusicTimeRight.Parent   then MusicTimeRight.Visible    = v end
    if not v and MusicSeekKnob and MusicSeekKnob.Parent then MusicSeekKnob.Visible = false end
end

local function musicResetProgress()
    if MusicProgressFill and MusicProgressFill.Parent then
        MusicProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
    if MusicSeekKnob and MusicSeekKnob.Parent then
        MusicSeekKnob.Position = UDim2.new(0, 0, 0.5, 0)
    end
    if MusicTimeLeft  and MusicTimeLeft.Parent  then MusicTimeLeft.Text  = "0:00" end
    if MusicTimeRight and MusicTimeRight.Parent then MusicTimeRight.Text = "0:00" end
end

local function musicSetPlayState(state)
    if not (MusicPlayBtn and MusicPlayBtn.Parent) then return end
    if state == "idle" then
        MusicPlayBtn.Text             = "\226\150\182 Play & Broadcast"
        MusicPlayBtn.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
        musicIsPlaying = false; musicIsPaused = false; musicIsBusy = false
        if MusicSeekKnob and MusicSeekKnob.Parent then MusicSeekKnob.Visible = false end
    elseif state == "loading" then
        MusicPlayBtn.Text             = "\226\143\179 Loading..."
        MusicPlayBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        musicIsBusy = true
    elseif state == "playing" then
        MusicPlayBtn.Text             = "\226\143\184 Pause"
        MusicPlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        musicIsPlaying = true; musicIsPaused = false; musicIsBusy = false
        if MusicSeekKnob and MusicSeekKnob.Parent then MusicSeekKnob.Visible = true end
    elseif state == "paused" then
        MusicPlayBtn.Text             = "\226\150\182 Resume"
        MusicPlayBtn.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
        musicIsPlaying = false; musicIsPaused = true; musicIsBusy = false
        if MusicSeekKnob and MusicSeekKnob.Parent then MusicSeekKnob.Visible = true end
    elseif state == "error" then
        MusicPlayBtn.Text             = "\226\154\160 Error"
        MusicPlayBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        musicIsPlaying = false; musicIsPaused = false; musicIsBusy = false
        if MusicSeekKnob and MusicSeekKnob.Parent then MusicSeekKnob.Visible = false end
        task.delay(2.5, function()
            if not musicIsPlaying and not musicIsBusy then
                musicSetPlayState("idle")
            end
        end)
    end
end

local function musicPopulateTrackInfo(track)
    if type(track) ~= "table" then return end

    musicTrackToken = musicTrackToken + 1
    local myToken = musicTrackToken

    musicStopProgressLoop()
    if musicEndedConn then
        pcall(function() musicEndedConn:Disconnect() end)
        musicEndedConn = nil
    end
    local ap = getMusicAudioPlayer()
    pcall(function() ap:Stop() end)
    pcall(function() ap.SoundId = "" end)

    musicCurrentTrack = track

    if MusicSongTitle and MusicSongTitle.Parent then
        MusicSongTitle.Text = "\240\159\142\181 " .. tostring(track.title or "Unknown")
    end
    if MusicSongDuration and MusicSongDuration.Parent then
        MusicSongDuration.Text = "\226\143\177 " .. musicFormatTime(track.duration or 0)
    end

    musicResetProgress()
    if MusicTimeRight and MusicTimeRight.Parent then
        MusicTimeRight.Text = musicFormatTime(track.duration or 0)
    end
    musicSetProgressVisible(true)
    if MusicSeekKnob and MusicSeekKnob.Parent then MusicSeekKnob.Visible = false end

    if MusicBackBtn and MusicBackBtn.Parent then
        MusicBackBtn.Visible = (#musicCurrentResults > 0)
    end

    if MusicThumbnail and MusicThumbnail.Parent then
        MusicThumbnail.Image   = ""
        MusicThumbnail.Visible = true
        if MusicThumbPlaceholder and MusicThumbPlaceholder.Parent then
            MusicThumbPlaceholder.Visible = true
        end
    end
    if MusicResultsPanel and MusicResultsPanel.Parent then
        MusicResultsPanel.Visible = false
    end

    if type(track.thumbnail) == "string" and track.thumbnail ~= "" then
        local thumbUrl = track.thumbnail
        task.spawn(function()
            pcall(function() makefolder("ares music") end)
            local uniquePath = "ares music/music_thumb_" .. tostring(myToken) .. ".png"
            local asset = musicDownloadFile(thumbUrl, uniquePath)
            if myToken ~= musicTrackToken then return end
            if asset and MusicThumbnail and MusicThumbnail.Parent then
                MusicThumbnail.Image = asset
                if MusicThumbPlaceholder and MusicThumbPlaceholder.Parent then
                    MusicThumbPlaceholder.Visible = false
                end
            end

            pcall(function()
                if delfile then
                    delfile("ares music/music_thumb_" .. tostring(myToken - 1) .. ".png")
                end
            end)
        end)
    end

    musicSetPlayState("idle")
end

local function musicFetchTrackStream(trackObj)
    if not trackObj or not trackObj.media or not trackObj.media.transcodings then
        return nil, "No media"
    end
    local progressiveUrl
    for _, trans in ipairs(trackObj.media.transcodings) do
        if trans.format and trans.format.protocol == "progressive" then
            progressiveUrl = trans.url
            break
        end
    end
    if not progressiveUrl then return nil, "No direct MP3 stream" end
    local body = musicSafeGet(progressiveUrl .. "?client_id=" .. MUSIC_SC_CLIENT_ID)
    if not body then return nil, "Stream fetch failed" end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" or not data.url then return nil, "Bad stream data" end
    return data.url, nil
end

local function musicBroadcastPlay(streamUrl, title)
    local req = syn and syn.request or http and http.request or request
    if not req then return end
    musicLastBroadcastUrl = streamUrl
    local payload = {
        Action        = "play",
        StreamUrl     = streamUrl,
        Title         = title or "Unknown",
        Server        = JobId,
        StartedAt     = os.time(),
        BroadcasterId = RealUserId,
    }
    pcall(function()
        req({
            Url    = MUSIC_SYNC_URL .. "/" .. JobId .. ".json",
            Method = "PUT",
            Body   = HttpService:JSONEncode(payload)
        })
    end)
end

local function musicBroadcastStop()
    local req = syn and syn.request or http and http.request or request
    if not req then return end
    musicLastBroadcastUrl = ""
    pcall(function()
        req({ Url = MUSIC_SYNC_URL .. "/" .. JobId .. ".json", Method = "DELETE" })
    end)
end

local function musicPlayCurrentTrack()
    if not musicCurrentTrack or not musicCurrentTrack.sc_track then return end
    local myToken = musicTrackToken

    task.spawn(function()
        musicSetPlayState("loading")

        musicStopProgressLoop()
        if musicEndedConn then
            pcall(function() musicEndedConn:Disconnect() end)
            musicEndedConn = nil
        end
        local ap = getMusicAudioPlayer()
        pcall(function() ap:Stop() end)
        pcall(function() ap.SoundId = "" end)
        musicResetProgress()
        musicSetProgressVisible(true)

        local streamUrl, err = musicFetchTrackStream(musicCurrentTrack.sc_track)
        if myToken ~= musicTrackToken then return end
        if not streamUrl then
            musicSetPlayState("error")
            if MusicPlayBtn and MusicPlayBtn.Parent then
                MusicPlayBtn.Text = "\226\154\160 " .. tostring(err)
            end
            return
        end

        if MusicPlayBtn and MusicPlayBtn.Parent then MusicPlayBtn.Text = "\226\143\179 Caching..." end
        pcall(function() makefolder("ares music") end)
        local audioAsset = musicDownloadFile(streamUrl, "ares music/music_creator.mp3")
        if myToken ~= musicTrackToken then return end

        local setOk = false
        if audioAsset then
            setOk = pcall(function() ap.SoundId = audioAsset end)
        end
        if not setOk then
            if MusicPlayBtn and MusicPlayBtn.Parent then MusicPlayBtn.Text = "\226\143\179 Streaming..." end
            pcall(function() ap.SoundId = streamUrl end)
        end

        pcall(function() ap.TimePosition = 0 end)
        pcall(function() ap:Play() end)
        musicSetPlayState("playing")
        musicStartProgressLoop()

        local broadcastTitle = musicCurrentTrack and musicCurrentTrack.title or "Unknown"
        task.spawn(function() musicBroadcastPlay(streamUrl, broadcastTitle) end)

        task.spawn(function()
            local ts = string.format("%012d", os.time()) .. math.random(100, 999)
            local pkt = {
                ["Sender"]      = "SYSTEM",
                ["SenderUid"]   = 0,
                ["Content"]     = "\240\159\142\181 " .. tostring(RealDisplayName) .. " playing: " .. broadcastTitle,
                ["Server"]      = JobId,
                ["IsSystem"]    = true,
                ["IsAutoClean"] = false
            }
            local req2 = syn and syn.request or http and http.request or request
            if req2 then
                pcall(function()
                    req2({ Url = DATABASE_URL .. "/" .. ts .. ".json", Method = "PUT", Body = HttpService:JSONEncode(pkt) })
                end)
            end
        end)

        musicEndedConn = ap.Ended:Connect(function()
            if musicEndedConn then
                pcall(function() musicEndedConn:Disconnect() end)
                musicEndedConn = nil
            end
            musicStopProgressLoop()
            musicResetProgress()
            musicIsPaused = false
            musicSetPlayState("idle")
            musicBroadcastStop()

            if musicLoopOn then
                task.defer(musicPlayCurrentTrack)
            elseif musicShuffleOn and #musicCurrentResults > 1 then
                local newIdx
                repeat newIdx = math.random(1, #musicCurrentResults) until newIdx ~= musicCurrentIndex
                musicCurrentIndex = newIdx
                musicPopulateTrackInfo(musicCurrentResults[musicCurrentIndex])
                task.defer(musicPlayCurrentTrack)
            elseif #musicCurrentResults > 0 and musicCurrentIndex < #musicCurrentResults then
                musicCurrentIndex = musicCurrentIndex + 1
                musicPopulateTrackInfo(musicCurrentResults[musicCurrentIndex])
                task.defer(musicPlayCurrentTrack)
            end
        end)
    end)
end

if CREATOR_IDS[RealUserId] or MUSIC_ACCESS_IDS[RealUserId] then
    local function musicClearResults()
        for _, c in ipairs(MusicResultsPanel:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end

    local function musicShowResults(results, appendMode)
        if not appendMode then
            musicClearResults()
        else

            for _, c in ipairs(MusicResultsPanel:GetChildren()) do
                if c:IsA("TextButton") and c.Name == "LoadMoreBtn" then c:Destroy() end
            end
        end
        MusicResultsPanel.Visible = true
        MusicThumbnail.Visible = false
        local startIdx = appendMode and (#musicCurrentResults - #results + 1) or 1
        for i, track in ipairs(results) do
            local globalIdx = appendMode and (startIdx + i - 1) or i
            local row = Instance.new("TextButton", MusicResultsPanel)
            row.LayoutOrder     = globalIdx
            row.Size            = UDim2.new(1, 0, 0, 22)
            row.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
            row.TextColor3      = Color3.new(1, 1, 1)
            row.Font            = Enum.Font.Gotham
            row.TextSize        = 10
            row.TextXAlignment  = Enum.TextXAlignment.Left
            row.TextTruncate    = Enum.TextTruncate.AtEnd
            row.Text            = "  " .. globalIdx .. ". " .. (track.title or "Unknown")
            row.ZIndex          = 3
            row.BorderSizePixel = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            row.MouseEnter:Connect(function() row.BackgroundColor3 = Color3.fromRGB(50, 50, 50) end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = Color3.fromRGB(32, 32, 32) end)
            local boundIdx = globalIdx
            row.MouseButton1Click:Connect(function()
                MusicResultsPanel.Visible = false
                musicCurrentIndex = boundIdx
                musicPopulateTrackInfo(musicCurrentResults[boundIdx])
            end)
        end

        local loadMoreBtn = Instance.new("TextButton", MusicResultsPanel)
        loadMoreBtn.Name           = "LoadMoreBtn"
        loadMoreBtn.LayoutOrder    = 99999
        loadMoreBtn.Size           = UDim2.new(1, 0, 0, 22)
        loadMoreBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 60)
        loadMoreBtn.TextColor3     = Color3.new(1, 1, 1)
        loadMoreBtn.Font           = Enum.Font.GothamBold
        loadMoreBtn.TextSize       = 10
        loadMoreBtn.Text           = "\226\172\135 Load More Songs"
        loadMoreBtn.ZIndex         = 3
        loadMoreBtn.BorderSizePixel = 0
        Instance.new("UICorner", loadMoreBtn).CornerRadius = UDim.new(0, 4)
        loadMoreBtn.MouseButton1Click:Connect(function()
            if not musicCurrentQuery or musicCurrentQuery == "" then return end
            loadMoreBtn.Text = "\226\143\179 Loading..."
            loadMoreBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            local nextOffset = musicCurrentOffset + 20
            task.spawn(function()
                local searchUrl = "https://api-v2.soundcloud.com/search/tracks?q="
                    .. HttpService:UrlEncode(musicCurrentQuery)
                    .. "&client_id=" .. MUSIC_SC_CLIENT_ID
                    .. "&limit=20&offset=" .. tostring(nextOffset)
                local body = musicSafeGet(searchUrl)
                if not body then
                    loadMoreBtn.Text = "\226\154\160 Error \226\128\148 try again"
                    loadMoreBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                    task.delay(2, function()
                        if loadMoreBtn and loadMoreBtn.Parent then
                            loadMoreBtn.Text = "\226\172\135 Load More Songs"
                            loadMoreBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 60)
                        end
                    end)
                    return
                end
                local decOk, data = pcall(function() return HttpService:JSONDecode(body) end)
                if not decOk or not data or type(data.collection) ~= "table" then
                    loadMoreBtn.Text = "\226\154\160 No more results"
                    loadMoreBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    return
                end
                local newResults = {}
                for _, scTrack in ipairs(data.collection) do
                    if scTrack.kind == "track" then
                        local hqThumb = scTrack.artwork_url
                        if hqThumb then hqThumb = hqThumb:gsub("-large%.jpg", "-t500x500.jpg") end
                        table.insert(newResults, {
                            title    = scTrack.title,
                            duration = scTrack.duration and math.floor(scTrack.duration / 1000) or 0,
                            thumbnail = hqThumb,
                            sc_track  = scTrack
                        })
                    end
                end
                if #newResults == 0 then
                    loadMoreBtn.Text = "\226\156\147 No more results"
                    loadMoreBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    return
                end
                musicCurrentOffset = nextOffset
                for _, t in ipairs(newResults) do table.insert(musicCurrentResults, t) end
                musicShowResults(newResults, true)
            end)
        end)
    end

    MusicBackBtn.MouseButton1Click:Connect(function()
        if #musicCurrentResults == 0 then return end
        MusicThumbnail.Visible = false
        MusicResultsPanel.Visible = true
    end)

    MusicSearchBtn.MouseButton1Click:Connect(function()
        local query = MusicSearchBox.Text
        if not query or query:match("^%s*$") then return end
        musicCurrentQuery  = query
        musicCurrentOffset = 0
        MusicResultsPanel.Visible = false
        MusicThumbnail.Visible = false
        MusicBackBtn.Visible = false
        MusicSearchBtn.Text             = "Searching..."
        MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

        task.spawn(function()
            local searchUrl = "https://api-v2.soundcloud.com/search/tracks?q="
                .. HttpService:UrlEncode(query)
                .. "&client_id=" .. MUSIC_SC_CLIENT_ID
                .. "&limit=20&offset=0"
            local body = musicSafeGet(searchUrl)
            if not body then
                MusicSearchBtn.Text             = "Net Error"
                MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                task.delay(2, function()
                    MusicSearchBtn.Text             = "\240\159\148\141 Search"
                    MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
                end)
                return
            end
            local decOk, data = pcall(function() return HttpService:JSONDecode(body) end)
            if not decOk or not data or type(data.collection) ~= "table" then
                MusicSearchBtn.Text             = "Bad Data"
                MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                task.delay(2, function()
                    MusicSearchBtn.Text             = "\240\159\148\141 Search"
                    MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
                end)
                return
            end
            local results = {}
            for _, scTrack in ipairs(data.collection) do
                if scTrack.kind == "track" then

                    local hqThumb = scTrack.artwork_url
                    if hqThumb then
                        hqThumb = hqThumb:gsub("-large%.jpg", "-t500x500.jpg")
                    end
                    table.insert(results, {
                        title     = scTrack.title,
                        duration  = scTrack.duration and math.floor(scTrack.duration / 1000) or 0,
                        thumbnail = hqThumb,
                        sc_track  = scTrack
                    })
                end
            end
            if #results == 0 then
                MusicSearchBtn.Text             = "No Results"
                MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                task.delay(2, function()
                    MusicSearchBtn.Text             = "\240\159\148\141 Search"
                    MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
                end)
                return
            end
            musicCurrentResults = results
            musicCurrentIndex   = 0
            musicCurrentOffset  = 0
            musicShowResults(results, false)
            MusicSearchBtn.Text             = "\226\156\147 " .. #results .. " found"
            MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 60)
            task.delay(1.5, function()
                MusicSearchBtn.Text             = "\240\159\148\141 Search"
                MusicSearchBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
            end)
        end)
    end)

    MusicPlayBtn.MouseButton1Click:Connect(function()
        if musicIsPaused then
            local ap = getMusicAudioPlayer()
            pcall(function() ap:Resume() end)
            musicSetPlayState("playing")
            musicStartProgressLoop()

            if musicCurrentTrack then
                task.spawn(function()
                    musicBroadcastPlay(musicLastBroadcastUrl, musicCurrentTrack.title or "Unknown")
                end)
            end
            return
        end
        if musicIsPlaying then
            local ap = getMusicAudioPlayer()
            pcall(function() ap:Pause() end)
            musicStopProgressLoop()
            musicSetPlayState("paused")
            return
        end
        if musicIsBusy then return end
        if not musicCurrentTrack then
            if MusicPlayBtn and MusicPlayBtn.Parent then
                MusicPlayBtn.Text = "Pick a song first!"
                task.delay(1.5, function() musicSetPlayState("idle") end)
            end
            return
        end
        musicTrackToken = musicTrackToken + 1
        musicPlayCurrentTrack()
    end)

    MusicStopBtn.MouseButton1Click:Connect(function()
        musicTrackToken = musicTrackToken + 1
        musicStopProgressLoop()
        if musicEndedConn then
            pcall(function() musicEndedConn:Disconnect() end)
            musicEndedConn = nil
        end
        local ap = getMusicAudioPlayer()
        pcall(function() ap:Stop() end)
        pcall(function() ap.SoundId = "" end)
        musicSetPlayState("idle")
        musicSetProgressVisible(false)
        musicResetProgress()
        musicBroadcastStop()
        if MusicSongTitle and MusicSongTitle.Parent then
            MusicSongTitle.Text = "No song selected"
        end
        if MusicSongDuration and MusicSongDuration.Parent then
            MusicSongDuration.Text = "Duration: 0:00"
        end
        if MusicThumbnail and MusicThumbnail.Parent then
            MusicThumbnail.Visible = false
            MusicThumbnail.Image = ""
        end
        MusicBackBtn.Visible = false
    end)

    MusicPrevBtn.MouseButton1Click:Connect(function()
        if #musicCurrentResults == 0 then return end
        musicTrackToken = musicTrackToken + 1
        if musicShuffleOn and #musicCurrentResults > 1 then
            local newIdx
            repeat newIdx = math.random(1, #musicCurrentResults) until newIdx ~= musicCurrentIndex
            musicCurrentIndex = newIdx
        else
            musicCurrentIndex = musicCurrentIndex - 1
            if musicCurrentIndex < 1 then musicCurrentIndex = #musicCurrentResults end
        end
        musicPopulateTrackInfo(musicCurrentResults[musicCurrentIndex])
        musicPlayCurrentTrack()
    end)

    MusicNextBtn.MouseButton1Click:Connect(function()
        if #musicCurrentResults == 0 then return end
        musicTrackToken = musicTrackToken + 1
        if musicShuffleOn and #musicCurrentResults > 1 then
            local newIdx
            repeat newIdx = math.random(1, #musicCurrentResults) until newIdx ~= musicCurrentIndex
            musicCurrentIndex = newIdx
        else
            musicCurrentIndex = musicCurrentIndex + 1
            if musicCurrentIndex > #musicCurrentResults then musicCurrentIndex = 1 end
        end
        musicPopulateTrackInfo(musicCurrentResults[musicCurrentIndex])
        musicPlayCurrentTrack()
    end)

    MusicShuffleBtn.MouseButton1Click:Connect(function()
        musicShuffleOn = not musicShuffleOn
        if musicShuffleOn then
            MusicShuffleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
            MusicShuffleBtn.TextColor3       = Color3.new(1, 1, 1)
        else
            MusicShuffleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            MusicShuffleBtn.TextColor3       = Color3.fromRGB(160, 160, 160)
        end
    end)

    MusicLoopBtn.MouseButton1Click:Connect(function()
        musicLoopOn = not musicLoopOn
        if musicLoopOn then
            MusicLoopBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
            MusicLoopBtn.TextColor3       = Color3.new(1, 1, 1)
        else
            MusicLoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            MusicLoopBtn.TextColor3       = Color3.fromRGB(160, 160, 160)
        end
    end)

    MusicNowPlayingLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            musicVolIdx = (musicVolIdx % #musicVolLevels) + 1
            local ap = getMusicAudioPlayer()
            ap.Volume = musicVolLevels[musicVolIdx]
            if MusicVolLabel and MusicVolLabel.Parent then
                MusicVolLabel.Text = "Vol: " .. tostring(math.floor(musicVolLevels[musicVolIdx] * 100)) .. "%"
            end
        end
    end)

    local function musicSeekToX(inputX)
        local ap = getMusicAudioPlayer()
        local len = ap.TimeLength
        if not len or len <= 0 then return end
        if not musicIsPlaying and not musicIsPaused then return end
        local barX  = MusicProgressBG.AbsolutePosition.X
        local barW  = MusicProgressBG.AbsoluteSize.X
        local ratio = math.clamp((inputX - barX) / barW, 0, 1)
        ap.TimePosition = ratio * len
        if MusicProgressFill and MusicProgressFill.Parent then
            MusicProgressFill.Size = UDim2.new(ratio, 0, 1, 0)
        end
        if MusicSeekKnob and MusicSeekKnob.Parent then
            MusicSeekKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
        end
        if MusicTimeLeft and MusicTimeLeft.Parent then
            MusicTimeLeft.Text = musicFormatTime(ratio * len)
        end
    end

    MusicProgressBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            musicIsSeeking = true
            musicSeekToX(input.Position.X)
        end
    end)

    MusicProgressBG.InputChanged:Connect(function(input)
        if musicIsSeeking and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            musicSeekToX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            musicIsSeeking = false
        end
    end)

    MusicSearchBox.FocusLost:Connect(function(enter)
        if enter then MusicSearchBtn.MouseButton1Click:Fire() end
    end)
end


local _musicListenerLastData = ""
local _musicListenerAP       = nil

local function getMusicListenerPlayer()
    if not _musicListenerAP or not _musicListenerAP.Parent then
        _musicListenerAP = Instance.new("Sound")
        _musicListenerAP.Parent = game:GetService("SoundService")
        _musicListenerAP.Volume = 1
        _musicListenerAP.Name   = "AresMusicListener"
    end
    return _musicListenerAP
end

task.spawn(function()

    task.wait(3)
    while true do
        task.wait(2)
        pcall(function()
            local req = syn and syn.request or http and http.request or request
            if not req then return end
            local res = req({ Url = MUSIC_SYNC_URL .. "/" .. JobId .. ".json", Method = "GET" })
            if not res or not res.Success then return end

            local body = res.Body
            if body == "null" or body == "" then

                if _musicListenerLastData ~= "null" and _musicListenerLastData ~= "" then
                    _musicListenerLastData = "null"
                    pcall(function()
                        local ap = getMusicListenerPlayer()
                        ap:Stop()
                        ap.SoundId = ""
                    end)
                end
                return
            end

            if body == _musicListenerLastData then return end
            _musicListenerLastData = body

            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if not ok or type(data) ~= "table" then return end
            if data.Action ~= "play" then return end
            if data.BroadcasterId == RealUserId then return end 

            local streamUrl = data.StreamUrl
            local title     = data.Title or "Unknown"
            if not streamUrl or streamUrl == "" then return end

            task.spawn(function()
                pcall(function() makefolder("ares music") end)
                local ap = getMusicListenerPlayer()
                ap:Stop()
                ap.SoundId = ""

                local audioAsset
                pcall(function()
                    local body2 = musicSafeGet(streamUrl)
                    if body2 and #body2 > 0 then
                        local wOk = pcall(writefile, "ares music/music_listener.mp3", body2)
                        if wOk then
                            task.wait(0.08)
                            pcall(function() audioAsset = getcustomasset("ares music/music_listener.mp3") end)
                        end
                    end
                end)

                local setOk = false
                if audioAsset then
                    setOk = pcall(function() ap.SoundId = audioAsset end)
                end
                if not setOk then
                    pcall(function() ap.SoundId = streamUrl end)
                end

                pcall(function() ap.TimePosition = 0 end)
                pcall(function() ap:Play() end)
            end)
        end)
    end
end)

task.spawn(function() while task.wait(0.5) do sync() end end)

local lastUnsentData = ""
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local req = syn and syn.request or http and http.request or request
            if not req then return end
            local res = req({Url = UNSENT_URL .. ".json", Method = "GET"})
            if not res.Success or res.Body == "null" or res.Body == lastUnsentData then return end
            lastUnsentData = res.Body
            local ok, unsentData = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if not ok or type(unsentData) ~= "table" then return end
            for fbKey, _ in pairs(unsentData) do
                local btn = keyToButton[fbKey]
                if btn then
                    local wf = btn and btn.Parent
                    keyToButton[fbKey] = nil
                    SpecialLabels[btn] = nil
                    NormalTitleLabels[btn] = nil
                    local newKeys = {}
                    for _, sk in ipairs(sortedMessageKeys) do
                        if sk ~= fbKey then table.insert(newKeys, sk) end
                    end
                    sortedMessageKeys = newKeys
                    if wf and wf.Parent then
                        TweenService:Create(btn,
                            TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                            {BackgroundTransparency = 1}):Play()
                        task.delay(0.16, function()
                            if wf and wf.Parent then wf:Destroy() end
                        end)
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(10) do
        syncCustomTitles()
    end
end)

task.spawn(function()
    while task.wait(30) do
        local elapsed = os.time() - lastMessageTime
        if elapsed >= IDLE_CLEAR_SECONDS then

            local hasMessages = false
            for _, child in pairs(ChatLog:GetChildren()) do
                if child:IsA("Frame") then hasMessages = true break end
            end
            if hasMessages then

                for _, child in pairs(ChatLog:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
                sortedMessageKeys = {}
                keyToButton = {}

                local req = syn and syn.request or http and http.request or request
                if req then
                    pcall(function()
                        req({Url = DATABASE_URL .. ".json", Method = "DELETE"})
                    end)
                end
                processedKeys = {}
                lastData = ""

                lastMessageTime = os.time()
            end
        end
    end
end)












do
    local RP_NAME_TEXT  = "\226\152\134\228\185\130\239\188\161\239\189\146\239\189\133\239\189\147 \226\149\172 \239\188\178\239\189\133\239\189\131\239\189\136\239\189\129\239\189\148\228\185\130\226\152\134"
    local RP_NAME_COLOR = Color3.fromRGB(255, 255, 153) 

    local function autoSetRpName()
        if game.PlaceId ~= 4924922222 then return end 
        local rs = game:GetService("ReplicatedStorage")
        local rpRemote = rs:FindFirstChild("RE")
        if not rpRemote then return end
        local nameRemote = rpRemote:FindFirstChild("1RPNam1eTex1t")
        if not nameRemote then return end

        
        pcall(function()
            local nameArgs = {
                [1] = "RolePlayName",
                [2] = RP_NAME_TEXT,
            }
            nameRemote:FireServer(table.unpack(nameArgs))
        end)

        
        pcall(function()
            local colorArgs = {
                [1] = "RolePlayNameColor", 
                [2] = RP_NAME_COLOR,
            }
            nameRemote:FireServer(table.unpack(colorArgs))
        end)
    end

    task.spawn(function()
        task.wait(2) 
        autoSetRpName()
    end)
end