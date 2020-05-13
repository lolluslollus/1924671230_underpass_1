function data()
    return {
        info = {
            minorVersion = 5,
            severityAdd = "NONE",
            severityRemove = "CRITICAL",
            name = _("name"),
            description = _("desc"),
            authors = {
                {
                    name = "Enzojz",
                    role = "CREATOR",
                    text = "Idea, Scripting, Modeling, Texturing",
                    steamProfile = "enzojz",
                    tfnetId = 27218,
                }
            },
            tags = {"Street Construction", "Tunnel"},
        },
        runFn = function(_)
            game.config.underpassMod = true
        end
    }
end
