// Managed by cachy-omarchy-dots' theme-engine (theme-set.sh), copied over
// ~/.config/niri/dms/colors.kdl on every theme switch - not DMS's own
// generated copy of that file. DMS is supposed to regenerate this file
// itself when its active theme changes, but that didn't reliably happen
// when the theme was switched externally (via cachy-menu patching
// settings.json rather than through DMS's own Settings UI), leaving niri's
// border/focus-ring colors stuck on whatever theme was active last. This
// is a close approximation of DMS's own color derivation, not a perfect
// replica of its Material-You tonal palette generation.

layout {
    background-color "transparent"

    focus-ring {
        active-color   "{{ accent }}"
        inactive-color "{{ color8 }}"
        urgent-color   "{{ color1 }}"
    }

    border {
        active-color   "{{ accent }}"
        inactive-color "{{ color8 }}"
        urgent-color   "{{ color1 }}"
    }

    shadow {
        color "#00000070"
    }

    tab-indicator {
        active-color   "{{ accent }}"
        inactive-color "{{ color8 }}"
        urgent-color   "{{ color1 }}"
    }

    insert-hint {
        color "{{ accent }}80"
    }
}

recent-windows {
    highlight {
        active-color   "{{ color8 }}"
        urgent-color   "{{ color1 }}"
    }
}
