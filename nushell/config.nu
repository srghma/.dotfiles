# 1. Disable the startup banner
$env.config.show_banner = false

# 2. Table styling (rounded, basic, compact, light, reinforced)
$env.config.table.mode = "light"

# 3. Enable Vi mode (default is "emacs")
$env.config.edit_mode = "vi"

# 4. History settings
$env.config.history = {
    file_format: "plaintext" # or "sqlite" for rich metadata
    max_size: 100_000
    sync_on_enter: true
}

$env.config.cursor_shape = {
    emacs: line
    vi_insert: line
    vi_normal: block
}

$env.config.keybindings ++= [
    {
        name: alt_h_left
        modifier: alt
        keycode: char_h
        mode: [vi_insert]
        event: { edit: MoveLeft }
    }
    {
        name: alt_j_down
        modifier: alt
        keycode: char_j
        mode: [vi_insert]
        event: { send: Down }
    }
    {
        name: alt_k_up
        modifier: alt
        keycode: char_k
        mode: [vi_insert]
        event: { send: Up }
    }
    {
        name: alt_l_complete_or_right
        modifier: alt
        keycode: char_l
        mode: [vi_insert]
        event: {
            until: [
                { send: HistoryHintComplete }
                { send: MenuRight }
                { edit: MoveRight }
            ]
        }
    }
    {
        name: shift_a_complete_or_end_insert
        modifier: shift
        keycode: char_a
        mode: [vi_normal]
        event: {
            until: [
                { send: HistoryHintComplete }
                { edit: MoveToLineEnd }
            ]
        }
    }
    {
        name: ctrl_u_delete_to_line_start
        modifier: control
        keycode: char_u
        mode: [vi_insert]
        event: { edit: CutFromLineStart }
    }
]

# Use Neovim to edit the current command line (CTRL+o)
# $env.config.buffer_editor = "nvim"

# esc v v doesnt work
# $env.config.keybindings ++= [{
#     name: edit_command_line
#     modifier: none
#     keycode: char_v
#     mode: vi_normal
#     event: { send: OpenEditor }
# }]
