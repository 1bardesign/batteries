return {
    std = "lua51+love",
    ignore = {
        "143", -- Accessing an undefined field of a global variable.
        "211", -- Unused local variable.
        "212", -- Unused argument.
        "212/self", -- Unused argument self.
        "213", -- Unused loop variable.
        "231", -- Local variable is set but never accessed.
        "311", -- Value assigned to a local variable is unused.
        "412", -- Redefining an argument.
        "413", -- Redefining a loop variable.
        "421", -- Shadowing a local variable.
        "422", -- Shadowing an argument.
        "423", -- Shadowing a loop variable.
        "423", -- Shadowing a loop variable.
        "432", -- Shadowing an upvalue argument.
        "611", -- A line consists of nothing but whitespace.
        "612", -- A line contains trailing whitespace.
        "614", -- Trailing whitespace in a comment.
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
            },
        },
        ["sort.lua"] = {
            ignore = {
                "142", -- Setting an undefined field of a global variable. (inside export)
            },
        },
    }
}
