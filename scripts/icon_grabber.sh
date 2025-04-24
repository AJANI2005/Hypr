#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <app_name>"
  exit 1
fi

# Normalize input: lowercase, strip common prefixes
input=$(echo "$1" | tr '[:upper:]' '[:lower:]')
input=$(echo "$input" | sed -E 's/^(com|org|net)\.//; s/.*\.//')

icon_dirs=(
  "$HOME/.icons"
  "/usr/share/icons/Papirus"
  "/usr/share/icons/hicolor"
  "/usr/share/pixmaps"
)

score_desktop_file() {
  local file="$1"
  local name=$(grep -i "^Name=" "$file" | cut -d= -f2 | tr '[:upper:]' '[:lower:]')
  local exec=$(grep -i "^Exec=" "$file" | cut -d= -f2 | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
  local basename=$(basename "$file" .desktop | tr '[:upper:]' '[:lower:]')

  local score=0
  for field in "$name" "$exec" "$basename"; do
    [[ "$field" == "$input" ]] && score=3 && break
    [[ "$field" == "$input"* ]] && score=2 && break
    [[ "$field" == *"$input"* ]] && score=1 && break
  done

  echo "$score:$file"
}

resolve_icon_path() {
  local icon="$1"
  # If full path is given in desktop file
  [[ -f "$icon" ]] && echo "$icon" && return

  for dir in "${icon_dirs[@]}"; do
    for ext in svg png xpm; do
      found=$(find "$dir" -type f -iname "$icon.$ext" 2>/dev/null | head -n 1)
      [ -n "$found" ] && echo "$found" && return
    done
  done
}

find_best_desktop_icon() {
  local best=""
  local best_score=0

  while IFS= read -r file; do
    entry=$(score_desktop_file "$file")
    score=${entry%%:*}
    path=${entry#*:}

    if (( score > best_score )); then
      icon_name=$(grep -i "^Icon=" "$path" | cut -d= -f2 | head -n 1)
      resolved=$(resolve_icon_path "$icon_name")
      if [ -n "$resolved" ]; then
        best_score=$score
        best=$resolved
      fi
    fi
  done < <(find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null)

  [ -n "$best" ] && echo "$best"
}

fallback_icon_match() {
  for dir in "${icon_dirs[@]}"; do
    for sub in "" "/apps" "/scalable/apps"; do
      for ext in svg png xpm; do
        for pattern in "$input" "$input-*" "*-$input" "*$input*"; do
          found=$(find "$dir$sub" -type f -iname "$pattern.$ext" 2>/dev/null | head -n 1)
          [ -n "$found" ] && echo "$found" && return
        done
      done
    done
  done
}

# Try main method
icon_path=$(find_best_desktop_icon)
[ -n "$icon_path" ] && echo "$icon_path" && exit 0

# Try fallback
icon_path=$(fallback_icon_match)
[ -n "$icon_path" ] && echo "$icon_path" && exit 0

echo "Icon not found for: $1"
exit 1

