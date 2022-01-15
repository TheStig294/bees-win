if engine.ActiveGamemode() == "terrortown" then
    CreateConVar("ttt_bees_win_suicide_bomb", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Whether the bees should win through a suicide bomb kill", 0, 1)

    CreateConVar("ttt_bees_win_death_link", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Whether the bees should win through a death link kill", 0, 1)

    hook.Add("PreRegisterSWEP", "BeeWinDeathLink", function(SWEP, class)
        if class == "weapon_ttt_death_link" then
            function playerDeath(victim, inflictor, attacker)
                if (not SERVER) then return end
                if (victim == attacker or victim:GetNWBool("deathlink_used", false)) then return end
                local ent = victim:GetNWEntity("deathlinked_player", nil)

                if (IsValid(ent)) then
                    ent:SetNWEntity("deathlinked_player", nil)
                    victim:SetNWEntity("deathlinked_player", nil)
                    local explosion = ents.Create("env_explosion")
                    explosion:SetPos(ent:GetPos())
                    explosion:SetOwner(victim)
                    explosion:SetKeyValue("iMagnitude", 180)
                    explosion:SetKeyValue("rendermode", "4")
                    explosion:Spawn()
                    explosion:Fire("Explode", "", 0)
                    explosion:EmitSound("siege/big_explosion.wav", 500, 500)
                    local effect = EffectData()
                    effect:SetOrigin(ent:GetPos())
                    util.Effect("Explosion_2_FireSmoke", effect)

                    timer.Simple(1, function()
                        ent:SetNWBool("deathlink_used", true)
                        victim:SetNWBool("deathlink_used", true)
                    end)
                end
            end

            hook.Add("PlayerDeath", "ttt_death_link_hook", playerDeath)
        end
    end)

    hook.Add("Initialize", "BeeWinInitialize", function()
        WIN_BEE = GenerateNewWinID and GenerateNewWinID(ROLE_NONE) or 234
        SetGlobalInt("WIN_BEE", WIN_BEE)

        if CLIENT then
            LANG.AddToLanguage("english", "win_bee", "The bees have stung their way to a win!")
            LANG.AddToLanguage("english", "ev_win_bee", "The bees have stung their way to a win!")
        end
    end)

    if SERVER then
        hook.Add("DoPlayerDeath", "BeeWinSuicideBomb", function(ply, attacker, dmg)
            if IsPlayer(attacker) and IsValid(attacker:GetActiveWeapon()) and (attacker:GetActiveWeapon():GetClass() == "weapon_john_bomb" or attacker:GetActiveWeapon():GetClass() == "weapon_ttt_suicide" or attacker:GetActiveWeapon():GetClass() == "weapon_ttt_jihad") then
                attacker:SetNWBool("UsedSuicideBomb", true)

                timer.Simple(1, function()
                    attacker:SetNWBool("UsedSuicideBomb", false)
                end)
            end
        end)

        hook.Add("TTTPrintResultMessage", "BeeWinMessage", function(win_type)
            if win_type == WIN_BEE then
                LANG.Msg("win_bee")
                ServerLog("Result: Bees win.\n")

                return true
            end
        end)

        hook.Add("TTTCheckForWin", "BeeWinCheck", function()
            local bees_win = true

            for _, p in ipairs(player.GetAll()) do
                if (p:Alive() and not p:IsSpec()) or (p:GetNWBool("UsedSuicideBomb") and not GetConVar("ttt_bees_win_suicide_bomb"):GetBool()) or (not p:GetNWBool("deathlink_used", true) and not GetConVar("ttt_bees_win_death_link"):GetBool()) then
                    bees_win = false
                    break
                end
            end

            if bees_win then return WIN_BEE end
        end)
    end

    if CLIENT then
        hook.Add("TTTEndRound", "SyncBeeWinID", function()
            WIN_BEE = GetGlobalInt("WIN_BEE")
            hook.Remove("TTTEndRound", "SyncBeeWinID")
        end)

        hook.Add("TTTScoringWinTitle", "BeeWinScoring", function(wintype, wintitle, title)
            if wintype == WIN_BEE then
                return {
                    txt = "hilite_win_role_plural",
                    params = {
                        role = "BEES"
                    },
                    c = Color(245, 200, 0, 255)
                }
            end
        end)

        hook.Add("TTTEventFinishText", "BeeWinFinishText", function(e)
            if e.win == WIN_BEE then return LANG.GetTranslation("ev_win_bee") end
        end)

        hook.Add("TTTEventFinishIconText", "BeeWinEventFinishText", function(e, win_string, role_string)
            if e.win == WIN_BEE then return win_string, "BEES" end
        end)
    end
end