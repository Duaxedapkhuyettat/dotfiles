if status is-interactive
    fastfetch
    zoxide init fish | source
    set -gx MICRO_TRUECOLOR 1
    set -gx EDITOR micro
    oh-my-posh init fish --config ~/.config/catppuccin_mocha.omp.json | source
end
