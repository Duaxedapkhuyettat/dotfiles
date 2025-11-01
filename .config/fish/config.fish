if status is-interactive
    fastfetch
    zoxide init fish | source
    set -gx MICRO_TRUECOLOR 1
    set -gx EDITOR micro
    starship init fish | source
end
