return {
    std = "lua51+love",
    ignore = {
        "211", -- Unused local variable.
        "212/self", -- Unused argument self.
        "213", -- Unused loop variable.
        "214", -- used _ prefix variable (we use this often to indicate private variables, not unused)
        "631", -- Line is too long.
    },
    files = {
        ["tests.lua"] = {
            ignore = {
                "211", -- Unused local variable. (testy will find these local functions)
            },
        },
        ["assert.lua"] = {
            ignore = {
                "121", -- Setting a read-only global variable. (we clobber assert)
            },
        },
        ["init.lua"] = {
            ignore = {
                "111", -- Setting an undefined global variable. (batteries and ripairs)
                "121", -- Setting a read-only global variable. (we clobber assert)
                "143", -- Accessing an undefined field of a global variable. (we use tablex as table)
            },
        },
        ["sort.lua"] = {
            ignore = {
                "142", -- Setting an undefined field of a global variable. (inside export)
            },
        },
    }
}
