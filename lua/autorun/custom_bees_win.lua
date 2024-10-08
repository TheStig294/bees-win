if engine.ActiveGamemode() == "terrortown" then
    CreateConVar("ttt_bees_win_suicide_bomb", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Whether the bees should win through a suicide bomb kill", 0, 1)

    CreateConVar("ttt_bees_win_death_link", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Whether the bees should win through a death link kill", 0, 1)

    hook.Add("PlayerDeath", "ttt_death_link_hook", function(victim, inflictor, attacker)
        if not SERVER then return end
        if victim == attacker or victim:GetNWBool("deathlink_used", false) then return end
        local ent = victim:GetNWEntity("deathlinked_player", nil)

        if IsValid(ent) then
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
    end)

    hook.Add("Initialize", "BeeWinInitialize", function()
        if SERVER then
            WIN_BEE = GenerateNewWinID and GenerateNewWinID(ROLE_NONE) or 234
            SetGlobalInt("WIN_BEE", WIN_BEE)
        end

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

        local soloWinJesters = {ROLE_CUPID, ROLE_FRENCHMAN}

        hook.Add("TTTCheckForWin", "BeeWinCheck", function()
            for _, ply in player.Iterator() do
                -- No bees win if...
                -- There's a player still alive and they're not a passive win role
                if ply:Alive() and not ply:IsSpec() and not ply:IsJesterTeam() and not ROLE_HAS_PASSIVE_WIN[ply:GetRole()] and not table.HasValue(soloWinJesters, ply:GetRole()) then return end
                -- Someone recently used the suicide bomb, and the bees win with it isn't turned on
                if ply:GetNWBool("UsedSuicideBomb") and not GetConVar("ttt_bees_win_suicide_bomb"):GetBool() then return end
                -- Someone used the death link weapon, and the bees win with it isn't turned on
                if not ply:GetNWBool("deathlink_used", true) and not GetConVar("ttt_bees_win_death_link"):GetBool() then return end
                -- Someone is in the process of respawning with the second chance item
                if ply.NOWINASC then return end
            end

            return WIN_BEE
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